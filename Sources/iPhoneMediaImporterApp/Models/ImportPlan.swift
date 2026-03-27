import Foundation

struct ImportPlanItem: Identifiable {
    let id: UUID
    let asset: MediaAsset
    let destinationDirectory: URL
    let destinationFileURL: URL
    let shouldSkip: Bool
    let skipReason: String?

    init(asset: MediaAsset, destinationDirectory: URL, destinationFileURL: URL, shouldSkip: Bool, skipReason: String? = nil) {
        self.id = UUID()
        self.asset = asset
        self.destinationDirectory = destinationDirectory
        self.destinationFileURL = destinationFileURL
        self.shouldSkip = shouldSkip
        self.skipReason = skipReason
    }
}

struct ImportPlan {
    let items: [ImportPlanItem]
    let summary: PlannedImportSummary

    var totalBytes: Int64 {
        items.reduce(0) { partialResult, item in
            partialResult + (item.shouldSkip ? 0 : item.asset.fileSize)
        }
    }
}
