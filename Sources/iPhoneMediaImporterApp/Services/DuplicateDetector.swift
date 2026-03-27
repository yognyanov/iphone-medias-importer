import Foundation

struct DuplicateDetector {
    private let metadataKeys: Set<URLResourceKey> = [.fileSizeKey, .creationDateKey, .contentModificationDateKey]

    func isKnownDuplicate(asset: MediaAsset, manifest: ImportManifest, baseFolder: URL) -> Bool {
        let signature = AssetSignature(asset: asset)
        return manifest.importedAssets.contains { existing in
            guard existing.looselyMatches(signature) else {
                return false
            }

            guard let destinationRelativePath = existing.destinationRelativePath else {
                return false
            }

            let destinationURL = baseFolder.appending(path: destinationRelativePath, directoryHint: .notDirectory)
            return FileManager.default.fileExists(atPath: destinationURL.path)
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

    func isDuplicate(asset: MediaAsset, in directoryURL: URL) -> Bool {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(metadataKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        return fileURLs.contains { isDuplicate(asset: asset, at: $0) }
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
