import Foundation

final class BookmarkStore {
    private let bookmarkKey = "selectedTargetFolderBookmark"
    private let defaults = UserDefaults.standard

    func save(url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(bookmark, forKey: bookmarkKey)
    }

    func restoreURL() -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    func clear() {
        defaults.removeObject(forKey: bookmarkKey)
    }

    func withSecurityScopedAccess<T>(to url: URL?, _ operation: () throws -> T) rethrows -> T? {
        guard let url else {
            return nil
        }

        let startedAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }
}
