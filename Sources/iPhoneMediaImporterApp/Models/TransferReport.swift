import Foundation

struct TransferReport: Codable {
    let createdAt: Date
    let sourceDevice: String
    let targetFolderPath: String
    let copiedBytes: Int64
    let copiedPhotos: Int
    let copiedVideos: Int
    let skippedFiles: Int
    let failedFiles: Int
    let duration: TimeInterval
    let wasCancelled: Bool
}
