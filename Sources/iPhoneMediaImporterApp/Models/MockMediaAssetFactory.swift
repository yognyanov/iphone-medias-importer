import Foundation

enum MockMediaAssetFactory {
    static func makeAssets() -> [MediaAsset] {
        let now = Date()
        return [
            makeAsset(name: "IMG_1001.HEIC", size: 3_200_000, type: .photo, date: shifted(now, years: -1, months: -2)),
            makeAsset(name: "IMG_1002.JPG", size: 4_100_000, type: .photo, date: shifted(now, years: -1, months: -1)),
            makeAsset(name: "IMG_1003.PNG", size: 1_400_000, type: .photo, date: shifted(now, months: -4)),
            makeAsset(name: "VID_2001.MOV", size: 240_000_000, type: .video, date: shifted(now, months: -3)),
            makeAsset(name: "VID_2002.MP4", size: 180_000_000, type: .video, date: shifted(now, months: -1))
        ]
    }

    private static func shifted(_ date: Date, years: Int = 0, months: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: years, month: months), to: date) ?? date
    }

    private static func makeAsset(name: String, size: Int64, type: MediaType, date: Date) -> MediaAsset {
        MediaAsset(
            id: UUID().uuidString,
            sourceIdentifier: UUID().uuidString,
            fileName: name,
            fileSize: size,
            mediaType: type,
            createdAt: date,
            fingerprint: UUID().uuidString,
            cameraFile: nil
        )
    }
}
