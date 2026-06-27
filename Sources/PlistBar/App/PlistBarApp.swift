import SwiftUI

@main
struct PlistBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let viewModel = ServiceListViewModel()
        statusItemController = StatusItemController(viewModel: viewModel)
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.shutdown()
    }
}
