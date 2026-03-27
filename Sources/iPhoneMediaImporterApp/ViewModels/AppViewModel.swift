import AppKit
import Combine
import Foundation
import ImageCaptureCore
import SwiftUI
import UserNotifications

@MainActor
final class AppViewModel: ObservableObject {
    @Published var screenState: AppScreenState = .idle
    @Published var targetFolderURL: URL?
    @Published var scanSummary: ScanSummary = .empty
    @Published var transferProgress: TransferProgressSnapshot = .empty
    @Published var transferSummary: TransferSummary = .empty
    @Published var plannedImportSummary: PlannedImportSummary = .empty
    @Published var transferHistory: [TransferHistoryItem] = []
    @Published var selectedHistoryItem: TransferHistoryItem?
    @Published var historySearchText = ""
    @Published var historyFilter: HistoryFilter = .all
    @Published var historyVisibleCount = 5
    @Published var settings: AppSettings
    @Published var lastErrorMessage: String?
    @Published var assets: [MediaAsset] = []
    @Published var deviceStateTitle = AppLanguage.text("Cihaz bekleniyor", "Waiting for device")
    @Published var canScan = false
    @Published var isTransferPaused = false
    @Published var mediaTransferFilter: MediaTransferFilter = .all
    @Published var importDateFilter: ImportDateFilter = .default
    @Published var onlyTransferNewFiles = true

    let deviceBrowserService = DeviceBrowserService()
    private let bookmarkStore = BookmarkStore()
    private let settingsStore = AppSettingsStore()
    private let folderSelectionService = FolderSelectionService()
    private let mediaScannerService = MediaScannerService()
    private let importPlanner = ImportPlanner()
    private let transferHistoryService = TransferHistoryService()
    private let historyExportService = HistoryExportService()
    let transferCoordinator = TransferCoordinator()
    private let notificationService = NotificationService()
    private let logger = LoggerService()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let settingsStore = AppSettingsStore()
        let bookmarkStore = BookmarkStore()
        self.settings = settingsStore.load()
        AppLanguage.configure(self.settings.languagePreference)
        self.targetFolderURL = bookmarkStore.restoreURL()
        bindDeviceState()
        refreshTransferHistory()
        deviceBrowserService.start()
        historyVisibleCount = settings.keepHistoryVisibleCount
    }

    var isDemoMode: Bool {
        AppMode.current == .demo
    }

    var canStartCopy: Bool {
        guard targetFolderURL != nil else { return false }
        return plannedImportSummary.itemsToCopy > 0
    }

    var availableAssetYears: [Int] {
        let years = Set(assets.map { Calendar.current.component(.year, from: $0.createdAt) })
        let sortedYears = years.sorted(by: >)
        if sortedYears.isEmpty {
            return [importDateFilter.year]
        }
        return sortedYears
    }

    var availableMonthsForSelectedYear: [Int] {
        guard importDateFilter.mode == .specificMonth else {
            return Array(1...12)
        }

        let months = Set(
            assets
                .filter { Calendar.current.component(.year, from: $0.createdAt) == importDateFilter.year }
                .map { Calendar.current.component(.month, from: $0.createdAt) }
        )

        let sorted = months.sorted()
        return sorted.isEmpty ? Array(1...12) : sorted
    }

    var currentTransferStatusText: String {
        if screenState == .completed {
            return transferSummary.wasCancelled
                ? AppLanguage.text("İşlem iptal edildi", "Transfer cancelled")
                : AppLanguage.text("Kopyalama tamamlandı", "Transfer completed")
        }

        let fileName = transferProgress.currentFileName.lowercased()

        if [".jpg", ".jpeg", ".png", ".heic"].contains(where: { fileName.hasSuffix($0) }) {
            return AppLanguage.text("Şu anda resimler kopyalanıyor", "Copying photos")
        }

        if [".mp4", ".mov", ".avi", ".m4v"].contains(where: { fileName.hasSuffix($0) }) {
            return AppLanguage.text("Şu anda videolar kopyalanıyor", "Copying videos")
        }

        return AppLanguage.text("Kopyalama hazırlanıyor", "Preparing transfer")
    }

    var transferSpeedText: String {
        guard let bytesPerSecond = transferProgress.bytesPerSecond else {
            return "-"
        }

        return "\(FormattingHelpers.formattedByteCount(Int64(bytesPerSecond)))/sn"
    }

    var completionHeadlineText: String {
        transferSummary.wasCancelled
            ? AppLanguage.text("Aktarım durduruldu", "Transfer stopped")
            : AppLanguage.text("Aktarım tamamlandı", "Transfer completed")
    }

    var completionDetailText: String {
        if transferSummary.wasCancelled {
            return AppLanguage.text(
                "İşlem kullanıcı tarafından durduruldu. Aktarılan dosyalar hedef klasörde hazır.",
                "The transfer was stopped by the user. Copied files are available in the destination folder."
            )
        }

        return AppLanguage.isTurkish
            ? "\(transferSummary.copiedPhotos) fotoğraf ve \(transferSummary.copiedVideos) video başarıyla aktarıldı."
            : "\(transferSummary.copiedPhotos) photos and \(transferSummary.copiedVideos) videos were transferred successfully."
    }

    var deviceHelpMessage: String? {
        switch deviceBrowserService.connectionState {
        case .disconnected, .searching:
            return AppLanguage.text(
                "iPhone görünmüyorsa telefonun kilidini açın ve Bu Mac'e Güven onayını verin.",
                "If the iPhone does not appear, unlock the phone and confirm Trust This Mac."
            )
        case .accessRestricted:
            return AppLanguage.text(
                "Telefonun kilidini açık tutun ve gerekirse Bu Mac'e Güven onayını yeniden verin.",
                "Keep the phone unlocked and confirm Trust This Mac again if needed."
            )
        case .connected:
            return nil
        }
    }

    var filteredTransferHistory: [TransferHistoryItem] {
        transferHistory.filter { item in
            let matchesFilter: Bool
            switch historyFilter {
            case .all:
                matchesFilter = true
            case .completed:
                matchesFilter = !item.report.wasCancelled
            case .cancelled:
                matchesFilter = item.report.wasCancelled
            }

            let query = historySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch =
                query.isEmpty ||
                item.report.sourceDevice.localizedCaseInsensitiveContains(query) ||
                item.report.targetFolderPath.localizedCaseInsensitiveContains(query)

            return matchesFilter && matchesSearch
        }
    }

    var visibleTransferHistory: [TransferHistoryItem] {
        Array(filteredTransferHistory.prefix(historyVisibleCount))
    }

    var hasMoreHistory: Bool {
        filteredTransferHistory.count > historyVisibleCount
    }

    func chooseTargetFolder() {
        guard let url = folderSelectionService.pickFolder() else {
            return
        }

        do {
            try bookmarkStore.save(url: url)
            targetFolderURL = url
            refreshTransferHistory()
            refreshPlannedImportSummary()
            historyVisibleCount = settings.keepHistoryVisibleCount
            selectedHistoryItem = transferHistory.first
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearTargetFolderSelection() {
        bookmarkStore.clear()
        targetFolderURL = nil
        scanSummary = .empty
        transferSummary = .empty
        plannedImportSummary = .empty
        transferProgress = .empty
        assets = []
        transferHistory = []
        selectedHistoryItem = nil
    }

    func scanDevice() {
        Task {
            do {
                lastErrorMessage = nil
                let scannedAssets = try await mediaScannerService.scanMedia(on: deviceBrowserService.currentDevice())
                assets = scannedAssets
                scanSummary = ScanSummary(
                    totalPhotos: scannedAssets.filter { $0.mediaType == .photo }.count,
                    totalVideos: scannedAssets.filter { $0.mediaType == .video }.count,
                    totalBytes: scannedAssets.reduce(0) { $0 + $1.fileSize },
                    deviceLabel: deviceBrowserService.activeDeviceName ?? (isDemoMode ? "Demo iPhone" : "-")
                )
                refreshPlannedImportSummary()
                screenState = .scanned
            } catch {
                lastErrorMessage = error.localizedDescription
                screenState = .error
                logger.error("Scan failed: \(error.localizedDescription)")
            }
        }
    }

    func retryDeviceConnection() {
        lastErrorMessage = nil
        deviceBrowserService.refresh()
    }

    func startCopy() {
        guard let targetFolderURL else {
            lastErrorMessage = AppLanguage.text("Lütfen hedef klasör seçin.", "Please select a destination folder.")
            return
        }

        let plan = importPlanner.buildPlan(
            for: assets,
            baseFolder: targetFolderURL,
            mediaFilter: mediaTransferFilter,
            dateFilter: importDateFilter,
            onlyNewFiles: onlyTransferNewFiles
        )
        guard plan.summary.itemsToCopy > 0 else {
            plannedImportSummary = plan.summary
            lastErrorMessage = AppLanguage.text("Aktarılacak yeni medya dosyası bulunamadı.", "No new media files were found to transfer.")
            return
        }
        plannedImportSummary = plan.summary
        transferProgress = TransferProgressSnapshot(
            totalFiles: plan.items.count,
            copiedFiles: 0,
            copiedPhotos: 0,
            copiedVideos: 0,
            skippedFiles: 0,
            failedFiles: 0,
            copiedBytes: 0,
            totalBytes: plan.totalBytes,
            currentFileName: "-",
            bytesPerSecond: nil,
            estimatedRemainingTime: nil
        )
        isTransferPaused = false
        screenState = .copying

        Task {
            do {
                transferSummary = try await transferCoordinator.transfer(
                    plan: plan,
                    targetFolder: targetFolderURL,
                    sourceDeviceName: scanSummary.deviceLabel,
                    settings: settings
                ) { [weak self] progress in
                    self?.transferProgress = progress
                }
                refreshTransferHistory()
                if settings.autoOpenTargetFolderAfterTransfer {
                    openTargetFolder()
                }
                if settings.showCompletionNotification {
                    notificationService.notifyTransferCompleted(summary: transferSummary)
                }
                isTransferPaused = false
                screenState = .completed
            } catch {
                if let transferError = error as? TransferCoordinatorError, transferError == .cancelled {
                    transferSummary = TransferSummary(
                        copiedBytes: transferProgress.copiedBytes,
                        copiedPhotos: transferProgress.copiedPhotos,
                        copiedVideos: transferProgress.copiedVideos,
                        skippedFiles: transferProgress.skippedFiles,
                        failedFiles: transferProgress.failedFiles,
                        duration: 0,
                        logFileURL: nil,
                        reportFileURL: nil,
                        wasCancelled: true,
                        sourceDeviceName: scanSummary.deviceLabel
                    )
                }
                isTransferPaused = false
                lastErrorMessage = error.localizedDescription
                screenState = .error
                logger.error("Transfer failed: \(error.localizedDescription)")
            }
        }
    }

    func pauseTransfer() {
        isTransferPaused = true
        transferCoordinator.pause()
    }

    func resumeTransfer() {
        isTransferPaused = false
        transferCoordinator.resume()
    }

    func cancelTransfer() {
        isTransferPaused = false
        transferCoordinator.cancel()
    }

    func openTargetFolder() {
        guard let targetFolderURL else { return }
        NSWorkspace.shared.open(targetFolderURL)
    }

    func openErrorLog() {
        guard let logURL = transferSummary.logFileURL else { return }
        NSWorkspace.shared.open(logURL)
    }

    func openTransferReport() {
        guard let reportURL = transferSummary.reportFileURL else { return }
        NSWorkspace.shared.open(reportURL)
    }

    func openHistoryReport(_ item: TransferHistoryItem) {
        selectedHistoryItem = item
        NSWorkspace.shared.open(item.reportURL)
    }

    func refreshTransferHistory() {
        transferHistory = bookmarkStore.withSecurityScopedAccess(to: targetFolderURL) {
            transferHistoryService.loadHistory(from: targetFolderURL)
        } ?? []
        if let selectedHistoryItem, !transferHistory.contains(where: { $0.id == selectedHistoryItem.id }) {
            self.selectedHistoryItem = transferHistory.first
        } else if self.selectedHistoryItem == nil {
            self.selectedHistoryItem = transferHistory.first
        }
    }

    func showMoreHistory() {
        historyVisibleCount += 10
    }

    func deleteHistoryItem(_ item: TransferHistoryItem) {
        do {
            _ = try bookmarkStore.withSecurityScopedAccess(to: targetFolderURL) {
                try transferHistoryService.deleteHistoryItem(item)
            }
            refreshTransferHistory()
        } catch {
            lastErrorMessage = AppLanguage.text(
                "Rapor silinemedi: \(error.localizedDescription)",
                "Could not delete report: \(error.localizedDescription)"
            )
        }
    }

    func clearHistory() {
        do {
            _ = try bookmarkStore.withSecurityScopedAccess(to: targetFolderURL) {
                try transferHistoryService.clearHistory(from: targetFolderURL)
            }
            refreshTransferHistory()
            selectedHistoryItem = nil
        } catch {
            lastErrorMessage = AppLanguage.text(
                "Geçmiş temizlenemedi: \(error.localizedDescription)",
                "Could not clear history: \(error.localizedDescription)"
            )
        }
    }

    func selectHistoryItem(_ item: TransferHistoryItem) {
        selectedHistoryItem = item
    }

    func exportHistoryCSV() {
        guard let targetFolderURL else {
            lastErrorMessage = AppLanguage.text(
                "CSV dışa aktarmak için önce hedef klasör seçin.",
                "Please choose a destination folder before exporting CSV."
            )
            return
        }

        do {
            let exportURL = try bookmarkStore.withSecurityScopedAccess(to: targetFolderURL) {
                try historyExportService.exportCSV(items: filteredTransferHistory, to: targetFolderURL)
            }
            guard let exportURL else {
                lastErrorMessage = AppLanguage.text(
                    "CSV dışa aktarımı için klasör erişimi sağlanamadı.",
                    "Folder access was not available for CSV export."
                )
                return
            }
            NSWorkspace.shared.open(exportURL)
        } catch {
            lastErrorMessage = AppLanguage.text(
                "CSV dışa aktarımı başarısız: \(error.localizedDescription)",
                "CSV export failed: \(error.localizedDescription)"
            )
        }
    }

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        var updated = settings
        mutate(&updated)
        settingsStore.save(updated)
        AppLanguage.configure(updated.languagePreference)
        settings = updated
        deviceStateTitle = deviceBrowserService.connectionState.title
        historyVisibleCount = updated.keepHistoryVisibleCount
    }

    func updateMediaTransferFilter(_ filter: MediaTransferFilter) {
        mediaTransferFilter = filter
        refreshPlannedImportSummary()
    }

    func updateImportDateFilterMode(_ mode: ImportDateFilterMode) {
        importDateFilter.mode = mode

        if (mode == .specificYear || mode == .specificMonth), let firstYear = availableAssetYears.first {
            importDateFilter.year = firstYear
        }

        if mode == .specificMonth, let firstMonth = availableMonthsForSelectedYear.first {
            importDateFilter.month = firstMonth
        }

        refreshPlannedImportSummary()
    }

    func updateImportDateFilterYear(_ year: Int) {
        importDateFilter.year = year

        if importDateFilter.mode == .specificMonth, let firstMonth = availableMonthsForSelectedYear.first {
            importDateFilter.month = firstMonth
        }

        refreshPlannedImportSummary()
    }

    func updateImportDateFilterMonth(_ month: Int) {
        importDateFilter.month = month
        refreshPlannedImportSummary()
    }

    func updateOnlyTransferNewFiles(_ newValue: Bool) {
        onlyTransferNewFiles = newValue
        refreshPlannedImportSummary()
    }

    private func bindDeviceState() {
        deviceBrowserService.$connectionState
            .sink { [weak self] state in
                guard let self else { return }
                self.deviceStateTitle = state.title
                switch state {
                case .connected, .accessRestricted:
                    self.canScan = true
                case .searching, .disconnected:
                    self.canScan = false
                }
            }
            .store(in: &cancellables)

        deviceBrowserService.$activeDeviceName
            .sink { [weak self] _ in
                guard let self else { return }
                self.deviceStateTitle = self.deviceBrowserService.connectionState.title
                switch self.deviceBrowserService.connectionState {
                case .connected, .accessRestricted:
                    self.canScan = true
                case .searching, .disconnected:
                    self.canScan = false
                }
            }
            .store(in: &cancellables)

        deviceBrowserService.$connectionState
            .dropFirst()
            .sink { [weak self] state in
                guard let self else { return }
                if self.screenState == .copying, !state.isConnected {
                    self.transferCoordinator.cancel()
                    self.lastErrorMessage = AppLanguage.text(
                        "iPhone bağlantısı kesildi. Kopyalama güvenli şekilde durduruldu.",
                        "The iPhone connection was lost. The transfer was stopped safely."
                    )
                    self.screenState = .error
                }
            }
            .store(in: &cancellables)
    }

    private func refreshPlannedImportSummary() {
        guard let targetFolderURL, !assets.isEmpty else {
            plannedImportSummary = .empty
            return
        }

        plannedImportSummary = importPlanner.buildPlan(
            for: assets,
            baseFolder: targetFolderURL,
            mediaFilter: mediaTransferFilter,
            dateFilter: importDateFilter,
            onlyNewFiles: onlyTransferNewFiles
        ).summary
    }
}

private final class NotificationService {
    func notifyTransferCompleted(summary: TransferSummary) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            let isAuthorized: Bool
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                isAuthorized = true
            case .notDetermined:
                isAuthorized = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            case .denied:
                isAuthorized = false
            @unknown default:
                isAuthorized = false
            }

            guard isAuthorized else { return }

            let content = UNMutableNotificationContent()
            content.title = AppLanguage.text("Aktarım tamamlandı", "Transfer completed")
            content.body = AppLanguage.isTurkish
                ? "\(summary.copiedPhotos) fotoğraf ve \(summary.copiedVideos) video aktarıldı. Toplam veri: \(FormattingHelpers.formattedByteCount(summary.copiedBytes))."
                : "\(summary.copiedPhotos) photos and \(summary.copiedVideos) videos were transferred. Total data: \(FormattingHelpers.formattedByteCount(summary.copiedBytes))."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            try? await center.add(request)
        }
    }
}
