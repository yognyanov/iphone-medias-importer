import Foundation

struct ScanSummary {
    let totalPhotos: Int
    let totalVideos: Int
    let totalBytes: Int64
    let deviceLabel: String

    static let empty = ScanSummary(totalPhotos: 0, totalVideos: 0, totalBytes: 0, deviceLabel: "-")
}
