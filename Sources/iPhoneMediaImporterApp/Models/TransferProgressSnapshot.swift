import Foundation

struct TransferProgressSnapshot {
    let totalFiles: Int
    let copiedFiles: Int
    let copiedPhotos: Int
    let copiedVideos: Int
    let skippedFiles: Int
    let failedFiles: Int
    let copiedBytes: Int64
    let totalBytes: Int64
    let currentFileName: String
    let bytesPerSecond: Double?
    let estimatedRemainingTime: TimeInterval?

    var remainingFiles: Int {
        max(totalFiles - copiedFiles - skippedFiles - failedFiles, 0)
    }

    var remainingBytes: Int64 {
        max(totalBytes - copiedBytes, 0)
    }

    var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(copiedBytes) / Double(totalBytes), 0), 1)
    }

    static let empty = TransferProgressSnapshot(
        totalFiles: 0,
        copiedFiles: 0,
        copiedPhotos: 0,
        copiedVideos: 0,
        skippedFiles: 0,
        failedFiles: 0,
        copiedBytes: 0,
        totalBytes: 0,
        currentFileName: "-",
        bytesPerSecond: nil,
        estimatedRemainingTime: nil
    )
}
