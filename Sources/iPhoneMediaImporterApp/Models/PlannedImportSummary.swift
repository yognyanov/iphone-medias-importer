import Foundation

struct PlannedImportSummary {
    let totalItems: Int
    let itemsToCopy: Int
    let duplicateItems: Int

    static let empty = PlannedImportSummary(totalItems: 0, itemsToCopy: 0, duplicateItems: 0)
}
