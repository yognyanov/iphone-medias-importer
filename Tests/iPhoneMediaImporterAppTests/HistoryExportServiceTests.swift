import Foundation
import Testing
@testable import iPhoneMediaImporterApp

struct HistoryExportServiceTests {
    @Test
    func exportsHistoryAsCSV() throws {
        let service = HistoryExportService()
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)

        let report = TransferReport(
            createdAt: .now,
            sourceDevice: "Test iPhone",
            targetFolderPath: "/tmp/archive",
            copiedBytes: 1024,
            copiedPhotos: 2,
            copiedVideos: 1,
            skippedFiles: 0,
            failedFiles: 0,
            duration: 12,
            wasCancelled: false
        )
        let item = TransferHistoryItem(
            report: report,
            reportURL: folder.appending(path: "report.json", directoryHint: .notDirectory)
        )

        let csvURL = try service.exportCSV(items: [item], to: folder)
        let content = try String(contentsOf: csvURL)

        #expect(csvURL.pathExtension.lowercased() == "csv")
        #expect(content.contains("Test iPhone"))
        #expect(content.contains("copiedBytes"))
    }
}
