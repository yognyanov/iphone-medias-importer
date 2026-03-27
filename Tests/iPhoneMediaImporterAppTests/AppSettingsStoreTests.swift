import Foundation
import Testing
@testable import iPhoneMediaImporterApp

struct AppSettingsStoreTests {
    @Test
    func defaultSettingsAreReasonable() {
        let settings = AppSettings.default

        #expect(settings.autoOpenTargetFolderAfterTransfer == false)
        #expect(settings.saveTransferReports)
        #expect(settings.saveErrorLogs)
        #expect(settings.keepHistoryVisibleCount == 5)
    }
}
