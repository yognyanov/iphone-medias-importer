import SwiftUI

@main
struct IPhoneMediaImporterApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 980, minHeight: 720)
        }
        .defaultSize(width: 1100, height: 760)
    }
}
