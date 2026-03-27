import Foundation

struct TransferHistoryItem: Identifiable {
    let id: String
    let report: TransferReport
    let reportURL: URL

    init(report: TransferReport, reportURL: URL) {
        self.id = reportURL.path(percentEncoded: false)
        self.report = report
        self.reportURL = reportURL
    }
}
