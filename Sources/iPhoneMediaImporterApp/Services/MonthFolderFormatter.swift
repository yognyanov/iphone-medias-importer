import Foundation

struct MonthFolderFormatter {
    private let monthNames = [
        1: "01_Ocak",
        2: "02_Subat",
        3: "03_Mart",
        4: "04_Nisan",
        5: "05_Mayis",
        6: "06_Haziran",
        7: "07_Temmuz",
        8: "08_Agustos",
        9: "09_Eylul",
        10: "10_Ekim",
        11: "11_Kasim",
        12: "12_Aralik"
    ]

    func folderName(for month: Int) -> String {
        monthNames[month] ?? String(format: "%02d_Bilinmeyen", month)
    }
}
