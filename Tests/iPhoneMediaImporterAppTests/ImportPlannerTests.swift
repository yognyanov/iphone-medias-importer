import Foundation
import Testing
@testable import iPhoneMediaImporterApp

struct ImportPlannerTests {
    @Test
    func buildsYearAndMonthFoldersByMediaType() throws {
        let planner = ImportPlanner()
        let baseFolder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true, attributes: nil)

        let asset = MediaAsset(
            id: "1",
            sourceIdentifier: "source-1",
            fileName: "IMG_1234.HEIC",
            fileSize: 2048,
            mediaType: .photo,
            createdAt: makeDate(year: 2025, month: 3, day: 12),
            fingerprint: nil,
            cameraFile: nil
        )

        let plan = planner.buildPlan(for: [asset], baseFolder: baseFolder)
        let item = try #require(plan.items.first)

        #expect(item.destinationDirectory.path(percentEncoded: false).contains("Fotograflar/2025/03_Mart"))
        #expect(item.shouldSkip == false)
        #expect(plan.summary.totalItems == 1)
        #expect(plan.summary.itemsToCopy == 1)
        #expect(plan.summary.duplicateItems == 0)
    }

    @Test
    func skipsItemsAlreadyRecordedInManifest() throws {
        let planner = ImportPlanner()
        let manifestStore = ImportManifestStore()
        let baseFolder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true, attributes: nil)

        let createdAt = makeDate(year: 2024, month: 11, day: 5)
        let asset = MediaAsset(
            id: "2",
            sourceIdentifier: "source-2",
            fileName: "VID_0099.MOV",
            fileSize: 99_999,
            mediaType: .video,
            createdAt: createdAt,
            fingerprint: "fp-2",
            cameraFile: nil
        )

        try manifestStore.save(
            ImportManifest(importedAssets: [AssetSignature(asset: asset)]),
            to: baseFolder
        )

        let plan = planner.buildPlan(for: [asset], baseFolder: baseFolder)
        let item = try #require(plan.items.first)

        #expect(item.shouldSkip)
        #expect(item.skipReason == "Manifest kaydina gore daha once aktarilmis.")
        #expect(plan.summary.duplicateItems == 1)
    }

    @Test
    func generatesSafeRenameWhenNameCollisionExistsButAssetIsDifferent() throws {
        let planner = ImportPlanner()
        let baseFolder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true, attributes: nil)

        let date = makeDate(year: 2025, month: 1, day: 1)
        let folder = baseFolder
            .appending(path: "Fotograflar", directoryHint: .isDirectory)
            .appending(path: "2025", directoryHint: .isDirectory)
            .appending(path: "01_Ocak", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)

        let existingFile = folder.appending(path: "IMG_7777.JPG", directoryHint: .notDirectory)
        try Data(repeating: 0, count: 12).write(to: existingFile)

        let asset = MediaAsset(
            id: "3",
            sourceIdentifier: "source-3",
            fileName: "IMG_7777.JPG",
            fileSize: 5000,
            mediaType: .photo,
            createdAt: date,
            fingerprint: nil,
            cameraFile: nil
        )

        let plan = planner.buildPlan(for: [asset], baseFolder: baseFolder)
        let item = try #require(plan.items.first)

        #expect(item.shouldSkip == false)
        #expect(item.destinationFileURL.lastPathComponent == "IMG_7777_1.JPG")
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}
