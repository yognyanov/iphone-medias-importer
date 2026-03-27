import Foundation

struct ImportManifest: Codable {
    var importedAssets: [AssetSignature]
}

struct ImportManifestStore {
    private let fileName = ".iphone-media-importer-manifest.json"

    func load(from baseFolder: URL) -> ImportManifest {
        let fileURL = manifestURL(in: baseFolder)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let data = try? Data(contentsOf: fileURL),
            let manifest = try? decoder.decode(ImportManifest.self, from: data)
        else {
            return ImportManifest(importedAssets: [])
        }

        return manifest
    }

    func save(_ manifest: ImportManifest, to baseFolder: URL) throws {
        let fileURL = manifestURL(in: baseFolder)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        try data.write(to: fileURL, options: .atomic)
    }

    func manifestURL(in baseFolder: URL) -> URL {
        baseFolder.appending(path: fileName, directoryHint: .notDirectory)
    }
}
