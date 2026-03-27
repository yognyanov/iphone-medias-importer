import Foundation

final class AppSettingsStore {
    private let defaults = UserDefaults.standard
    private let key = "appSettings"

    func load() -> AppSettings {
        guard
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }

        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
