import Foundation

enum AppMode: String {
    case live
    case demo

    static var current: AppMode {
        ProcessInfo.processInfo.environment["IPHONE_IMPORTER_DEMO"] == "1" ? .demo : .live
    }
}
