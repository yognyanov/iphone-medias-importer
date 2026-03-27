import Foundation

enum DeviceConnectionState: Equatable {
    case searching
    case disconnected
    case connected(name: String)
    case accessRestricted(message: String)

    var title: String {
        switch self {
        case .searching:
            return AppLanguage.text("Cihaz bekleniyor", "Waiting for device")
        case .disconnected:
            return AppLanguage.text("iPhone bağlı değil", "iPhone not connected")
        case let .connected(name):
            return AppLanguage.isTurkish ? "\(name) bağlı" : "Connected: \(FormattingHelpers.localizedDeviceName(name))"
        case let .accessRestricted(message):
            return message
        }
    }

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
