import Foundation

struct HistoryExportService {
    func exportCSV(items: [TransferHistoryItem], to folder: URL) throws -> URL {
        let formatter = ISO8601DateFormatter()
        let fileURL = folder.appending(path: "transfer-history-\(formatter.string(from: .now)).csv", directoryHint: .notDirectory)

        var lines = [
            "createdAt,sourceDevice,targetFolderPath,copiedBytes,copiedPhotos,copiedVideos,skippedFiles,failedFiles,duration,wasCancelled"
        ]

        for item in items {
            let report = item.report
            let line = [
                escape(formatter.string(from: report.createdAt)),
                escape(report.sourceDevice),
                escape(report.targetFolderPath),
                "\(report.copiedBytes)",
                "\(report.copiedPhotos)",
                "\(report.copiedVideos)",
                "\(report.skippedFiles)",
                "\(report.failedFiles)",
                "\(report.duration)",
                "\(report.wasCancelled)"
            ].joined(separator: ",")
            lines.append(line)
        }

        let content = lines.joined(separator: "\n")
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
