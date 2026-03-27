import Foundation

struct TransferReportWriter {
    func write(report: TransferReport, into baseFolder: URL) -> URL? {
        let reportsFolder = baseFolder.appending(path: "Reports", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: reportsFolder, withIntermediateDirectories: true, attributes: nil)

        let formatter = ISO8601DateFormatter()
        let fileURL = reportsFolder.appending(path: "transfer-report-\(formatter.string(from: .now)).json", directoryHint: .notDirectory)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(report) else {
            return nil
        }

        try? data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
