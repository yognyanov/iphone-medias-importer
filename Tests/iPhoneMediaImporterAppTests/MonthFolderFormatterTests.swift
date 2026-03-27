import Testing
@testable import iPhoneMediaImporterApp

struct MonthFolderFormatterTests {
    @Test
    func formatsKnownMonthNames() {
        let formatter = MonthFolderFormatter()

        #expect(formatter.folderName(for: 1) == "01_Ocak")
        #expect(formatter.folderName(for: 3) == "03_Mart")
        #expect(formatter.folderName(for: 11) == "11_Kasim")
    }

    @Test
    func fallsBackForUnknownMonth() {
        let formatter = MonthFolderFormatter()

        #expect(formatter.folderName(for: 13) == "13_Bilinmeyen")
    }
}
