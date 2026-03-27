import Foundation

struct DuplicateDetector {
    private let metadataKeys: Set<URLResourceKey> = [.fileSizeKey, .creationDateKey, .contentModificationDateKey]

    func isKnownDuplicate(asset: MediaAsset, manifest: ImportManifest) -> Bool {
        let signature = AssetSignature(asset: asset)
        return manifest.importedAssets.contains { existing in
            existing.looselyMatches(signature)
        }
    }

    func isDuplicate(asset: MediaAsset, at destinationURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            return false
        }

        guard
            let values = try? destinationURL.resourceValues(forKeys: metadataKeys),
            let fileSize = values.fileSize
        else {
            return false
        }

        let sameName = destinationURL.lastPathComponent.caseInsensitiveCompare(asset.fileName) == .orderedSame
        let sameSize = Int64(fileSize) == asset.fileSize
        let sameDate = compareDate(asset.createdAt, values.creationDate ?? values.contentModificationDate)
        return sameName && sameSize && sameDate
    }

    func resolvedUniqueURL(for preferredURL: URL) -> URL {
        guard FileManager.default.fileExists(atPath: preferredURL.path) else {
            return preferredURL
        }

        let directory = preferredURL.deletingLastPathComponent()
        let baseName = preferredURL.deletingPathExtension().lastPathComponent
        let ext = preferredURL.pathExtension

        for index in 1...9999 {
            let fileName = "\(baseName)_\(index).\(ext)"
            let candidate = directory.appending(path: fileName, directoryHint: .notDirectory)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return directory.appending(path: "\(baseName)_\(UUID().uuidString).\(ext)", directoryHint: .notDirectory)
    }

    private func compareDate(_ left: Date, _ right: Date?) -> Bool {
        guard let right else { return false }
        return abs(left.timeIntervalSince(right)) < 2
    }
}
