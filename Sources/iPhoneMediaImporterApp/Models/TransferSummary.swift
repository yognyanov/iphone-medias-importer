import Foundation

struct TransferSummary {
    let copiedBytes: Int64
    let copiedPhotos: Int
    let copiedVideos: Int
    let skippedFiles: Int
    let failedFiles: Int
    let duration: TimeInterval
    let logFileURL: URL?
    let reportFileURL: URL?
    let wasCancelled: Bool
    let sourceDeviceName: String

    static let empty = TransferSummary(
        copiedBytes: 0,
        copiedPhotos: 0,
        copiedVideos: 0,
        skippedFiles: 0,
        failedFiles: 0,
        duration: 0,
        logFileURL: nil,
        reportFileURL: nil,
        wasCancelled: false,
        sourceDeviceName: "-"
    )
}
