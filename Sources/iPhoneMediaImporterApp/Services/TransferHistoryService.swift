import Foundation

struct TransferHistoryService {
    func loadHistory(from baseFolder: URL?) -> [TransferHistoryItem] {
        guard let baseFolder else {
            return []
        }

        let reportsFolder = baseFolder.appending(path: "Reports", directoryHint: .isDirectory)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: reportsFolder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { url -> TransferHistoryItem? in
                guard
                    let data = try? Data(contentsOf: url),
                    let report = try? decoder.decode(TransferReport.self, from: data)
                else {
                    return nil
                }

                return TransferHistoryItem(report: report, reportURL: url)
            }
            .sorted { $0.report.createdAt > $1.report.createdAt }
    }

    func deleteHistoryItem(_ item: TransferHistoryItem) throws {
        try FileManager.default.removeItem(at: item.reportURL)
    }

    func clearHistory(from baseFolder: URL?) throws {
        guard let baseFolder else {
            return
        }

        let reportsFolder = baseFolder.appending(path: "Reports", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: reportsFolder.path) else {
            return
        }

        let urls = try FileManager.default.contentsOfDirectory(at: reportsFolder, includingPropertiesForKeys: nil)
        for url in urls where url.pathExtension.lowercased() == "json" {
            try FileManager.default.removeItem(at: url)
        }
    }
}
