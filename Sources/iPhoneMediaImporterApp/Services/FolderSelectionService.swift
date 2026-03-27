import AppKit
import Foundation

@MainActor
struct FolderSelectionService {
    func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = AppLanguage.text("Seç", "Select")
        panel.message = AppLanguage.text(
            "Medya dosyalarının kopyalanacağı klasörü seçin.",
            "Select the folder where media files will be copied."
        )
        return panel.runModal() == .OK ? panel.url : nil
    }
}
