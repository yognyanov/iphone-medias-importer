import Foundation

struct AssetSignature: Codable, Hashable {
    let sourceIdentifier: String
    let fileName: String
    let fileSize: Int64
    let createdAt: Date
    let fingerprint: String?

    init(
        sourceIdentifier: String,
        fileName: String,
        fileSize: Int64,
        createdAt: Date,
        fingerprint: String?
    ) {
        self.sourceIdentifier = sourceIdentifier
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.fingerprint = fingerprint
    }

    init(asset: MediaAsset) {
        self.sourceIdentifier = asset.sourceIdentifier
        self.fileName = asset.fileName
        self.fileSize = asset.fileSize
        self.createdAt = asset.createdAt
        self.fingerprint = asset.fingerprint
    }

    func looselyMatches(_ other: AssetSignature) -> Bool {
        if let fingerprint, let otherFingerprint = other.fingerprint, fingerprint == otherFingerprint {
            return true
        }

        return fileName.caseInsensitiveCompare(other.fileName) == .orderedSame &&
            fileSize == other.fileSize &&
            abs(createdAt.timeIntervalSince(other.createdAt)) < 2
    }
}
