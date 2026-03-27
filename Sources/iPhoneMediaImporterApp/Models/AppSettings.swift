import Foundation

struct AppSettings: Codable, Equatable {
    var autoOpenTargetFolderAfterTransfer: Bool
    var showCompletionNotification: Bool
    var saveTransferReports: Bool
    var saveErrorLogs: Bool
    var keepHistoryVisibleCount: Int

    static let `default` = AppSettings(
        autoOpenTargetFolderAfterTransfer: false,
        showCompletionNotification: true,
        saveTransferReports: true,
        saveErrorLogs: true,
        keepHistoryVisibleCount: 5
    )
}
