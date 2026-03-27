import Foundation

enum AppLanguage {
    private static let settingsKey = "appSettings"

    static func configure(_ preference: AppLanguagePreference) {
        // Language preference is read from persisted settings on demand so the
        // current UI can react without relying on shared mutable global state.
    }

    static var isTurkish: Bool {
        switch currentPreference {
        case .system:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("tr") == true
        case .turkish:
            return true
        case .english:
            return false
        }
    }

    static func text(_ turkish: String, _ english: String) -> String {
        isTurkish ? turkish : english
    }

    static var localeIdentifier: String {
        isTurkish ? "tr_TR" : "en_US"
    }

    private static var currentPreference: AppLanguagePreference {
        guard
            let data = UserDefaults.standard.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .system
        }

        return settings.languagePreference
    }
}

enum FormattingHelpers {
    static func formattedByteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else {
            return "-"
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter.string(from: duration) ?? "-"
    }

    static func formattedDateTime(_ date: Date?) -> String {
        guard let date else {
            return "-"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: AppLanguage.localeIdentifier)
        return formatter.string(from: date)
    }

    static func localizedDeviceName(_ name: String) -> String {
        guard !AppLanguage.isTurkish else {
            return name
        }

        let suffixes = ["’u", "’ü", "’ı", "’i", "'u", "'ü", "'ı", "'i"]
        for suffix in suffixes where name.hasSuffix(suffix) {
            return String(name.dropLast(suffix.count))
        }

        return name
    }
}
