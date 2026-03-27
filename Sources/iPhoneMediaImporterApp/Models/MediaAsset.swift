import Foundation
import ImageCaptureCore

struct MediaAsset: Identifiable, Hashable {
    let id: String
    let sourceIdentifier: String
    let fileName: String
    let fileSize: Int64
    let mediaType: MediaType
    let createdAt: Date
    let fingerprint: String?
    let cameraFile: ICCameraFile?

    init(cameraFile: ICCameraFile, mediaType: MediaType, createdAt: Date) {
        let resolvedName = cameraFile.name ?? cameraFile.originalFilename ?? UUID().uuidString
        let sourceIdentifier = cameraFile.fingerprint ?? "\(resolvedName)-\(cameraFile.fileSize)-\(createdAt.timeIntervalSince1970)"
        self.id = sourceIdentifier
        self.sourceIdentifier = sourceIdentifier
        self.fileName = resolvedName
        self.fileSize = Int64(cameraFile.fileSize)
        self.mediaType = mediaType
        self.createdAt = createdAt
        self.fingerprint = cameraFile.fingerprint
        self.cameraFile = cameraFile
    }

    init(
        id: String,
        sourceIdentifier: String,
        fileName: String,
        fileSize: Int64,
        mediaType: MediaType,
        createdAt: Date,
        fingerprint: String?,
        cameraFile: ICCameraFile?
    ) {
        self.id = id
        self.sourceIdentifier = sourceIdentifier
        self.fileName = fileName
        self.fileSize = fileSize
        self.mediaType = mediaType
        self.createdAt = createdAt
        self.fingerprint = fingerprint
        self.cameraFile = cameraFile
    }

    static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fileName)
        hasher.combine(fileSize)
    }
}
