import Foundation
@preconcurrency import ImageCaptureCore

@MainActor
struct MediaDateResolver {
    func resolveDate(for file: ICCameraFile, importDate: Date = .now) async -> Date {
        if let date = immediateDate(for: file) {
            return date
        }

        if let date = await metadataDate(for: file) {
            return date
        }

        return importDate
    }

    private func immediateDate(for file: ICCameraFile) -> Date? {
        if let date = file.exifCreationDate {
            return date
        }
        if let date = file.creationDate {
            return date
        }
        if let date = file.fileCreationDate {
            return date
        }
        if let date = file.modificationDate {
            return date
        }
        if let date = file.fileModificationDate {
            return date
        }
        return nil
    }

    private func metadataDate(for file: ICCameraFile) async -> Date? {
        await withCheckedContinuation { continuation in
            file.requestMetadataDictionary(options: nil) { metadata, _ in
                let parsed = metadata.flatMap { parseMetadataDate(from: $0) }
                continuation.resume(returning: parsed)
            }
        }
    }
}

private let prioritizedMetadataKeys: [String] = [
    "DateTimeOriginal",
    "CreationDate",
    "DateCreated",
    "DateTimeDigitized",
    "DateTime",
    "CreationTime",
    "com.apple.quicktime.creationdate"
]

private func parseMetadataDate(from metadata: [AnyHashable: Any]) -> Date? {
    for key in prioritizedMetadataKeys {
        if let value = metadata[key], let date = parseMetadataDateValue(value) {
            return date
        }
    }

    for value in metadata.values {
        if let nested = value as? [AnyHashable: Any], let date = parseMetadataDate(from: nested) {
            return date
        }
    }

    return nil
}

private func parseMetadataDateValue(_ value: Any) -> Date? {
    if let date = value as? Date {
        return date
    }

    if let string = value as? String {
        return parseMetadataDateString(string)
    }

    if let number = value as? NSNumber {
        return Date(timeIntervalSince1970: number.doubleValue)
    }

    return nil
}

private func parseMetadataDateString(_ value: String) -> Date? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let date = makeISO8601Formatter(withFractionalSeconds: true).date(from: trimmed) {
        return date
    }

    if let date = makeISO8601Formatter(withFractionalSeconds: false).date(from: trimmed) {
        return date
    }

    for formatter in makeDateFormatters() {
        if let date = formatter.date(from: trimmed) {
            return date
        }
    }

    return nil
}

private func makeISO8601Formatter(withFractionalSeconds: Bool) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = withFractionalSeconds
        ? [.withInternetDateTime, .withFractionalSeconds]
        : [.withInternetDateTime]
    return formatter
}

private func makeDateFormatters() -> [DateFormatter] {
    [
        makeDateFormatter("yyyy:MM:dd HH:mm:ss"),
        makeDateFormatter("yyyy-MM-dd HH:mm:ss"),
        makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss"),
        makeDateFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
        makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    ]
}

private func makeDateFormatter(_ format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = format
    return formatter
}
