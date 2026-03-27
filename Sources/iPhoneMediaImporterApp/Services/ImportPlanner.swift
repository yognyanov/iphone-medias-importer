import Foundation

struct ImportPlanner {
    private let duplicateDetector = DuplicateDetector()
    private let manifestStore = ImportManifestStore()
    private let monthFormatter = MonthFolderFormatter()
    private let calendar = Calendar(identifier: .gregorian)

    func buildPlan(
        for assets: [MediaAsset],
        baseFolder: URL,
        mediaFilter: MediaTransferFilter = .all,
        dateFilter: ImportDateFilter = .default,
        onlyNewFiles: Bool = false
    ) -> ImportPlan {
        let manifest = manifestStore.load(from: baseFolder)
        let filteredAssets = assets.filter {
            mediaFilter.includes($0.mediaType) && dateFilter.includes($0.createdAt, calendar: calendar)
        }
        let orderedAssets = filteredAssets.sorted(by: compareAssetsForTransferOrder)
        var duplicateItems = 0

        let items: [ImportPlanItem] = orderedAssets.compactMap { asset in
            let year = calendar.component(.year, from: asset.createdAt)
            let month = calendar.component(.month, from: asset.createdAt)
            let destinationDirectory = baseFolder
                .appending(path: asset.mediaType.folderName, directoryHint: .isDirectory)
                .appending(path: String(year), directoryHint: .isDirectory)
                .appending(path: monthFormatter.folderName(for: month), directoryHint: .isDirectory)

            let preferredURL = destinationDirectory.appending(path: asset.fileName, directoryHint: .notDirectory)
            if duplicateDetector.isKnownDuplicate(asset: asset, manifest: manifest) {
                duplicateItems += 1
                if onlyNewFiles {
                    return nil
                }

                return ImportPlanItem(
                    asset: asset,
                    destinationDirectory: destinationDirectory,
                    destinationFileURL: preferredURL,
                    shouldSkip: true,
                    skipReason: "Manifest kaydina gore daha once aktarilmis."
                )
            }

            if duplicateDetector.isDuplicate(asset: asset, at: preferredURL) {
                duplicateItems += 1
                if onlyNewFiles {
                    return nil
                }

                return ImportPlanItem(
                    asset: asset,
                    destinationDirectory: destinationDirectory,
                    destinationFileURL: preferredURL,
                    shouldSkip: true,
                    skipReason: "Ayni dosya daha once kopyalanmis."
                )
            }

            let uniqueURL = duplicateDetector.resolvedUniqueURL(for: preferredURL)
            return ImportPlanItem(
                asset: asset,
                destinationDirectory: destinationDirectory,
                destinationFileURL: uniqueURL,
                shouldSkip: false
            )
        }

        let itemsToCopy = items.filter { !$0.shouldSkip }.count
        let summary = PlannedImportSummary(
            totalItems: filteredAssets.count,
            itemsToCopy: itemsToCopy,
            duplicateItems: duplicateItems
        )

        return ImportPlan(items: items, summary: summary)
    }

    private func compareAssetsForTransferOrder(_ lhs: MediaAsset, _ rhs: MediaAsset) -> Bool {
        if lhs.mediaType != rhs.mediaType {
            return lhs.mediaType == .photo
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
    }
}
