import Foundation

enum MediaType: String, Codable, CaseIterable {
    case photo
    case video

    var folderName: String {
        switch self {
        case .photo:
            return "Fotograflar"
        case .video:
            return "Videolar"
        }
    }
}

enum MediaTransferFilter: String, Codable, CaseIterable {
    case all
    case photosOnly
    case videosOnly

    var title: String {
        switch self {
        case .all:
            return "Tümü"
        case .photosOnly:
            return "Sadece Fotoğraf"
        case .videosOnly:
            return "Sadece Video"
        }
    }

    func includes(_ mediaType: MediaType) -> Bool {
        switch self {
        case .all:
            return true
        case .photosOnly:
            return mediaType == .photo
        case .videosOnly:
            return mediaType == .video
        }
    }
}

enum ImportDateFilterMode: String, Codable, CaseIterable {
    case all
    case specificMonth
    case specificYear

    var title: String {
        switch self {
        case .all:
            return "Tümü"
        case .specificMonth:
            return "Belirli Ay"
        case .specificYear:
            return "Belirli Yıl"
        }
    }
}

struct ImportDateFilter: Codable, Equatable {
    var mode: ImportDateFilterMode
    var year: Int
    var month: Int

    static var `default`: ImportDateFilter {
        ImportDateFilter(
            mode: .all,
            year: Calendar.current.component(.year, from: .now),
            month: Calendar.current.component(.month, from: .now)
        )
    }

    func includes(_ date: Date, calendar: Calendar = .current) -> Bool {
        switch mode {
        case .all:
            return true
        case .specificMonth:
            return calendar.component(.year, from: date) == year && calendar.component(.month, from: date) == month
        case .specificYear:
            return calendar.component(.year, from: date) == year
        }
    }

    var summaryText: String {
        switch mode {
        case .all:
            return "Tümü"
        case .specificMonth:
            return "\(monthTitle) \(year)"
        case .specificYear:
            return "\(year)"
        }
    }

    var monthTitle: String {
        let titles = [
            "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
            "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
        ]
        guard month >= 1 && month <= titles.count else { return "-" }
        return titles[month - 1]
    }
}
