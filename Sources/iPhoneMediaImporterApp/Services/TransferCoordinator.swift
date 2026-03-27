import Foundation
@preconcurrency import ImageCaptureCore

enum TransferCoordinatorError: LocalizedError, Equatable {
    case targetFolderMissing
    case cancelled

    var errorDescription: String? {
        switch self {
        case .targetFolderMissing:
            return "Hedef klasor secilmedi."
        case .cancelled:
            return "Islem kullanici tarafindan iptal edildi."
        }
    }
}

private final class DownloadRequestState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?

    func install(_ continuation: CheckedContinuation<Void, Error>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func resume(_ result: Result<Void, Error>) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        lock.unlock()

        switch result {
        case .success:
            continuation.resume(returning: ())
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    func cancel() {
        resume(.failure(TransferCoordinatorError.cancelled))
    }
}

final class TransferCoordinator: @unchecked Sendable {
    private let logger = LoggerService()
    private let errorLogWriter = ErrorLogWriter()
    private let reportWriter = TransferReportWriter()
    private let manifestStore = ImportManifestStore()
    private let stateLock = NSLock()

    private var paused = false
    private var cancelled = false
    private var activeDownloadDevice: ICCameraDevice?
    private var activeDownloadRequest: DownloadRequestState?
    private var waitContinuation: CheckedContinuation<Void, Never>?

    func pause() {
        let (request, device) = interruptTransfer(paused: true, cancelled: false)
        request?.cancel()
        device?.cancelDownload()
        logger.info("Transfer paused.")
    }

    func resume() {
        let continuation = resumeTransferState()
        continuation?.resume()
        logger.info("Transfer resumed.")
    }

    func cancel() {
        let (request, device, continuation) = cancelTransferState()
        request?.cancel()
        device?.cancelDownload()
        continuation?.resume()
        logger.info("Transfer cancelled.")
    }

    func transfer(
        plan: ImportPlan,
        targetFolder: URL,
        sourceDeviceName: String,
        settings: AppSettings,
        progressHandler: @escaping @MainActor (TransferProgressSnapshot) -> Void
    ) async throws -> TransferSummary {
        let startedAccessing = targetFolder.startAccessingSecurityScopedResource()
        guard startedAccessing || targetFolder.isFileURL else {
            throw TransferCoordinatorError.targetFolderMissing
        }

        defer {
            if startedAccessing {
                targetFolder.stopAccessingSecurityScopedResource()
            }
            resetRuntimeState()
        }

        let startedAt = Date()
        var copiedFiles = 0
        var skippedFiles = 0
        var failedFiles = 0
        var copiedPhotos = 0
        var copiedVideos = 0
        var copiedBytes: Int64 = 0
        var errors: [TransferErrorRecord] = []
        var manifest = manifestStore.load(from: targetFolder)

        for item in plan.items {
            if isCancelledState() {
                throw TransferCoordinatorError.cancelled
            }

            if isPausedState() {
                await waitUntilResumed()
            }

            if item.shouldSkip {
                skippedFiles += 1
                await progressHandler(
                    makeProgressSnapshot(
                        totalFiles: plan.items.count,
                        copiedFiles: copiedFiles,
                        copiedPhotos: copiedPhotos,
                        copiedVideos: copiedVideos,
                        skippedFiles: skippedFiles,
                        failedFiles: failedFiles,
                        copiedBytes: copiedBytes,
                        totalBytes: plan.totalBytes,
                        currentFileName: item.asset.fileName,
                        startedAt: startedAt
                    )
                )
                continue
            }

            var shouldAdvanceToNextItem = false

            while !shouldAdvanceToNextItem {
                if isCancelledState() {
                    throw TransferCoordinatorError.cancelled
                }

                if isPausedState() {
                    await waitUntilResumed()
                }

                do {
                    try FileManager.default.createDirectory(at: item.destinationDirectory, withIntermediateDirectories: true, attributes: nil)
                    try await download(item: item)
                    copiedFiles += 1
                    copiedBytes += item.asset.fileSize
                    manifest.importedAssets.append(AssetSignature(asset: item.asset))

                    switch item.asset.mediaType {
                    case .photo:
                        copiedPhotos += 1
                    case .video:
                        copiedVideos += 1
                    }

                    shouldAdvanceToNextItem = true
                } catch {
                    if shouldRestartPausedDownload(for: error, item: item) {
                        await progressHandler(
                            makeProgressSnapshot(
                                totalFiles: plan.items.count,
                                copiedFiles: copiedFiles,
                                copiedPhotos: copiedPhotos,
                                copiedVideos: copiedVideos,
                                skippedFiles: skippedFiles,
                                failedFiles: failedFiles,
                                copiedBytes: copiedBytes,
                                totalBytes: plan.totalBytes,
                                currentFileName: item.asset.fileName,
                                startedAt: startedAt
                            )
                        )
                        continue
                    }

                    failedFiles += 1
                    errors.append(TransferErrorRecord(fileName: item.asset.fileName, message: error.localizedDescription))
                    logger.error("Transfer failed for \(item.asset.fileName): \(error.localizedDescription)")
                    shouldAdvanceToNextItem = true
                }
            }

            await progressHandler(
                makeProgressSnapshot(
                    totalFiles: plan.items.count,
                    copiedFiles: copiedFiles,
                    copiedPhotos: copiedPhotos,
                    copiedVideos: copiedVideos,
                    skippedFiles: skippedFiles,
                    failedFiles: failedFiles,
                    copiedBytes: copiedBytes,
                    totalBytes: plan.totalBytes,
                    currentFileName: item.asset.fileName,
                    startedAt: startedAt
                )
            )
        }

        try? manifestStore.save(manifest, to: targetFolder)
        let duration = Date().timeIntervalSince(startedAt)
        let logURL = settings.saveErrorLogs ? errorLogWriter.write(errors: errors, into: targetFolder) : nil
        let reportURL = settings.saveTransferReports
            ? reportWriter.write(
                report: TransferReport(
                    createdAt: .now,
                    sourceDevice: sourceDeviceName,
                    targetFolderPath: targetFolder.path(percentEncoded: false),
                    copiedBytes: copiedBytes,
                    copiedPhotos: copiedPhotos,
                    copiedVideos: copiedVideos,
                    skippedFiles: skippedFiles,
                    failedFiles: failedFiles,
                    duration: duration,
                    wasCancelled: false
                ),
                into: targetFolder
            )
            : nil

        return TransferSummary(
            copiedBytes: copiedBytes,
            copiedPhotos: copiedPhotos,
            copiedVideos: copiedVideos,
            skippedFiles: skippedFiles,
            failedFiles: failedFiles,
            duration: duration,
            logFileURL: logURL,
            reportFileURL: reportURL,
            wasCancelled: false,
            sourceDeviceName: sourceDeviceName
        )
    }

    private func makeProgressSnapshot(
        totalFiles: Int,
        copiedFiles: Int,
        copiedPhotos: Int,
        copiedVideos: Int,
        skippedFiles: Int,
        failedFiles: Int,
        copiedBytes: Int64,
        totalBytes: Int64,
        currentFileName: String,
        startedAt: Date
    ) -> TransferProgressSnapshot {
        let elapsed = max(Date().timeIntervalSince(startedAt), 1)
        let bytesPerSecond = Double(copiedBytes) / elapsed
        let remainingBytes = max(totalBytes - copiedBytes, 0)
        let estimate = bytesPerSecond > 0 ? Double(remainingBytes) / bytesPerSecond : nil

        return TransferProgressSnapshot(
            totalFiles: totalFiles,
            copiedFiles: copiedFiles,
            copiedPhotos: copiedPhotos,
            copiedVideos: copiedVideos,
            skippedFiles: skippedFiles,
            failedFiles: failedFiles,
            copiedBytes: copiedBytes,
            totalBytes: totalBytes,
            currentFileName: currentFileName,
            bytesPerSecond: bytesPerSecond > 0 ? bytesPerSecond : nil,
            estimatedRemainingTime: estimate
        )
    }

    private func waitUntilResumed() async {
        await withCheckedContinuation { continuation in
            if shouldWaitForResume() {
                installWaitContinuation(continuation)
            } else {
                continuation.resume()
            }
        }
    }

    private func shouldRestartPausedDownload(for error: Error, item: ImportPlanItem) -> Bool {
        guard !isCancelledState() else {
            return false
        }

        guard isPausedState(), error is TransferCoordinatorError else {
            return false
        }

        cleanupPartiallyDownloadedFile(for: item)
        logger.info("Transfer paused while downloading \(item.asset.fileName). Download will restart on resume.")
        return true
    }

    private func cleanupPartiallyDownloadedFile(for item: ImportPlanItem) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: item.destinationFileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: item.destinationFileURL)
        } catch {
            logger.error("Failed to remove partial file \(item.destinationFileURL.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private func download(item: ImportPlanItem) async throws {
        if AppMode.current == .demo {
            try await Task.sleep(for: .milliseconds(250))
            return
        }

        guard let cameraFile = item.asset.cameraFile else {
            throw CocoaError(.fileNoSuchFile)
        }

        let options: [ICDownloadOption: Any] = [
            .downloadsDirectoryURL: item.destinationDirectory,
            .saveAsFilename: item.destinationFileURL.lastPathComponent,
            .overwrite: false
        ]

        let requestState = DownloadRequestState()
        setActiveDownload(device: cameraFile.device, request: requestState)

        defer {
            clearActiveDownload()
        }

        logger.info("Download started for \(item.asset.fileName).")
        nonisolated(unsafe) let unsafeCameraFile = cameraFile
        try await Self.requestDownload(cameraFile: unsafeCameraFile, options: options, requestState: requestState)
    }

    private nonisolated static func requestDownload(
        cameraFile: ICCameraFile,
        options: [ICDownloadOption: Any],
        requestState: DownloadRequestState
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            requestState.install(continuation)
            guard cameraFile.requestDownload(options: options, completion: { _, error in
                if let error {
                    requestState.resume(.failure(error))
                } else {
                    requestState.resume(.success(()))
                }
            }) != nil else {
                requestState.resume(.failure(CocoaError(.fileWriteUnknown)))
                return
            }
        }
    }

    private func interruptTransfer(paused: Bool, cancelled: Bool) -> (DownloadRequestState?, ICCameraDevice?) {
        stateLock.lock()
        self.paused = paused
        self.cancelled = cancelled
        let request = activeDownloadRequest
        let device = activeDownloadDevice
        stateLock.unlock()
        return (request, device)
    }

    private func resumeTransferState() -> CheckedContinuation<Void, Never>? {
        stateLock.lock()
        paused = false
        let continuation = waitContinuation
        waitContinuation = nil
        stateLock.unlock()
        return continuation
    }

    private func cancelTransferState() -> (DownloadRequestState?, ICCameraDevice?, CheckedContinuation<Void, Never>?) {
        stateLock.lock()
        cancelled = true
        paused = false
        let request = activeDownloadRequest
        let device = activeDownloadDevice
        let continuation = waitContinuation
        waitContinuation = nil
        stateLock.unlock()
        return (request, device, continuation)
    }

    private func resetRuntimeState() {
        stateLock.lock()
        paused = false
        cancelled = false
        activeDownloadDevice = nil
        activeDownloadRequest = nil
        waitContinuation = nil
        stateLock.unlock()
    }

    private func isPausedState() -> Bool {
        stateLock.lock()
        let value = paused
        stateLock.unlock()
        return value
    }

    private func isCancelledState() -> Bool {
        stateLock.lock()
        let value = cancelled
        stateLock.unlock()
        return value
    }

    private func shouldWaitForResume() -> Bool {
        stateLock.lock()
        let value = paused && !cancelled
        stateLock.unlock()
        return value
    }

    private func installWaitContinuation(_ continuation: CheckedContinuation<Void, Never>) {
        stateLock.lock()
        if paused && !cancelled {
            waitContinuation = continuation
            stateLock.unlock()
        } else {
            stateLock.unlock()
            continuation.resume()
        }
    }

    private func setActiveDownload(device: ICCameraDevice?, request: DownloadRequestState?) {
        stateLock.lock()
        activeDownloadDevice = device
        activeDownloadRequest = request
        stateLock.unlock()
    }

    private func clearActiveDownload() {
        stateLock.lock()
        activeDownloadDevice = nil
        activeDownloadRequest = nil
        stateLock.unlock()
    }
}
