import AppKit
import Foundation

@MainActor
struct FolderSelectionService {
    func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Sec"
        panel.message = "Medya dosyalarinin kopyalanacagi klasoru secin."
        return panel.runModal() == .OK ? panel.url : nil
    }
}
