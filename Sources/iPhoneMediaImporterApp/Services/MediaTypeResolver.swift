import Foundation

struct MediaTypeResolver {
    private let photoExtensions = Set(["jpg", "jpeg", "png", "heic"])
    private let videoExtensions = Set(["mp4", "mov", "avi", "m4v"])

    func resolve(fileName: String) -> MediaType? {
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        if photoExtensions.contains(ext) {
            return .photo
        }
        if videoExtensions.contains(ext) {
            return .video
        }
        return nil
    }
}
