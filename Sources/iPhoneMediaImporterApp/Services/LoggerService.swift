import Foundation
import OSLog

struct LoggerService {
    private let logger: Logger

    init(category: String = "app") {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.example.iPhoneMediaImporter"
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
