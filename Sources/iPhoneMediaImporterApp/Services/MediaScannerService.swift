import Foundation
import ImageCaptureCore

enum MediaScannerError: LocalizedError {
    case noDevice
    case accessRestricted
    case failedToOpenSession(String)

    var errorDescription: String? {
        switch self {
        case .noDevice:
            return AppLanguage.text("Bağlı iPhone bulunamadı.", "No connected iPhone was found.")
        case .accessRestricted:
            return AppLanguage.text(
                "iPhone medya erişimi hazır değil. Cihaz kilidini açın ve gerekirse Bu Mac'e Güven onayını verin.",
                "iPhone media access is not ready. Unlock the device and confirm Trust This Mac if needed."
            )
        case let .failedToOpenSession(message):
            return AppLanguage.text("Cihaz oturumu açılamadı: \(message)", "Could not open device session: \(message)")
        }
    }
}

@MainActor
final class MediaScannerService {
    private let logger = LoggerService()
    private let dateResolver = MediaDateResolver()
    private let typeResolver = MediaTypeResolver()

    func scanMedia(on device: ICCameraDevice?) async throws -> [MediaAsset] {
        if AppMode.current == .demo {
            let files = MockMediaAssetFactory.makeAssets()
            logger.info("Demo scan completed with \(files.count) media items.")
            return files
        }

        guard let device else {
            throw MediaScannerError.noDevice
        }

        if device.isAccessRestrictedAppleDevice {
            throw MediaScannerError.accessRestricted
        }

        if device.capabilities.contains(ICDeviceCapability.cameraDeviceSupportsHEIF.rawValue) {
            device.mediaPresentation = .originalAssets
        }

        if !device.hasOpenSession {
            try await openSession(for: device)
        }

        if device.isAccessRestrictedAppleDevice {
            throw MediaScannerError.accessRestricted
        }

        var files: [MediaAsset] = []
        for case let file as ICCameraFile in (device.mediaFiles ?? []) {
            let name = file.name ?? file.originalFilename ?? ""
            guard let mediaType = typeResolver.resolve(fileName: name) else {
                continue
            }

            let date = await dateResolver.resolveDate(for: file)
            files.append(MediaAsset(cameraFile: file, mediaType: mediaType, createdAt: date))
        }

        files.sort { $0.createdAt < $1.createdAt }

        logger.info("Scan completed with \(files.count) media items.")
        return files
    }

    private func openSession(for device: ICCameraDevice) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            device.requestOpenSession(options: nil) { error in
                if let error {
                    continuation.resume(throwing: MediaScannerError.failedToOpenSession(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
