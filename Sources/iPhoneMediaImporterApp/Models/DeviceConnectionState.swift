import Foundation

enum DeviceConnectionState: Equatable {
    case searching
    case disconnected
    case connected(name: String)
    case accessRestricted(message: String)

    var title: String {
        switch self {
        case .searching:
            return "Cihaz bekleniyor"
        case .disconnected:
            return "iPhone bağlı değil"
        case let .connected(name):
            return "\(name) bağlı"
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
