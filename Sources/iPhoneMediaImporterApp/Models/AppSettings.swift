import Foundation

enum AppLanguagePreference: String, Codable, CaseIterable, Equatable {
    case system
    case turkish
    case english

    var title: String {
        switch self {
        case .system:
            return AppLanguage.text("Sistem", "System")
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var autoOpenTargetFolderAfterTransfer: Bool
    var showCompletionNotification: Bool
    var saveTransferReports: Bool
    var saveErrorLogs: Bool
    var keepHistoryVisibleCount: Int
    var languagePreference: AppLanguagePreference

    static let `default` = AppSettings(
        autoOpenTargetFolderAfterTransfer: false,
        showCompletionNotification: true,
        saveTransferReports: true,
        saveErrorLogs: true,
        keepHistoryVisibleCount: 5,
        languagePreference: .system
    )

    private enum CodingKeys: String, CodingKey {
        case autoOpenTargetFolderAfterTransfer
        case showCompletionNotification
        case saveTransferReports
        case saveErrorLogs
        case keepHistoryVisibleCount
        case languagePreference
    }

    init(
        autoOpenTargetFolderAfterTransfer: Bool,
        showCompletionNotification: Bool,
        saveTransferReports: Bool,
        saveErrorLogs: Bool,
        keepHistoryVisibleCount: Int,
        languagePreference: AppLanguagePreference
    ) {
        self.autoOpenTargetFolderAfterTransfer = autoOpenTargetFolderAfterTransfer
        self.showCompletionNotification = showCompletionNotification
        self.saveTransferReports = saveTransferReports
        self.saveErrorLogs = saveErrorLogs
        self.keepHistoryVisibleCount = keepHistoryVisibleCount
        self.languagePreference = languagePreference
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoOpenTargetFolderAfterTransfer = try container.decodeIfPresent(Bool.self, forKey: .autoOpenTargetFolderAfterTransfer) ?? Self.default.autoOpenTargetFolderAfterTransfer
        self.showCompletionNotification = try container.decodeIfPresent(Bool.self, forKey: .showCompletionNotification) ?? Self.default.showCompletionNotification
        self.saveTransferReports = try container.decodeIfPresent(Bool.self, forKey: .saveTransferReports) ?? Self.default.saveTransferReports
        self.saveErrorLogs = try container.decodeIfPresent(Bool.self, forKey: .saveErrorLogs) ?? Self.default.saveErrorLogs
        self.keepHistoryVisibleCount = try container.decodeIfPresent(Int.self, forKey: .keepHistoryVisibleCount) ?? Self.default.keepHistoryVisibleCount
        self.languagePreference = try container.decodeIfPresent(AppLanguagePreference.self, forKey: .languagePreference) ?? Self.default.languagePreference
    }
}
