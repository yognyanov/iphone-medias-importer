import Foundation

struct ErrorLogWriter {
    func write(errors: [TransferErrorRecord], into baseFolder: URL) -> URL? {
        guard !errors.isEmpty else {
            return nil
        }

        let logsFolder = baseFolder.appending(path: "Logs", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: logsFolder, withIntermediateDirectories: true, attributes: nil)

        let formatter = ISO8601DateFormatter()
        let fileURL = logsFolder.appending(path: "import-errors-\(formatter.string(from: .now)).json", directoryHint: .notDirectory)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(errors) else {
            return nil
        }

        try? data.write(to: fileURL)
        return fileURL
    }
}
