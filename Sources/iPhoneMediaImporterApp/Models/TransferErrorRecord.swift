import Foundation

struct TransferErrorRecord: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let message: String
    let timestamp: Date

    init(fileName: String, message: String, timestamp: Date = .now) {
        self.id = UUID()
        self.fileName = fileName
        self.message = message
        self.timestamp = timestamp
    }
}
