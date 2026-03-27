import Foundation

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Tumu"
        case .completed:
            return "Tamamlanan"
        case .cancelled:
            return "Iptal"
        }
    }
}
