import Foundation
import Testing
@testable import iPhoneMediaImporterApp

struct ImportManifestStoreTests {
    @Test
    func savesAndLoadsManifest() throws {
        let store = ImportManifestStore()
        let baseFolder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true, attributes: nil)

        let manifest = ImportManifest(
            importedAssets: [
                AssetSignature(
                    sourceIdentifier: "source",
                    fileName: "IMG_1.JPG",
                    fileSize: 42,
                    createdAt: .now,
                    fingerprint: "fingerprint"
                )
            ]
        )

        try store.save(manifest, to: baseFolder)
        let loaded = store.load(from: baseFolder)

        #expect(loaded.importedAssets.count == 1)
        #expect(loaded.importedAssets.first?.fileName == "IMG_1.JPG")
        #expect(store.manifestURL(in: baseFolder).lastPathComponent == ".iphone-media-importer-manifest.json")
    }
}
