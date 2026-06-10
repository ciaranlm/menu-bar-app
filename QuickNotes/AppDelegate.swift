import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep the app out of the Dock even if Info.plist is changed while debugging.
        NSApp.setActivationPolicy(.accessory)

        let statusItemController = StatusItemController(appState: appState)
        self.statusItemController = statusItemController

        let hotkeyManager = HotkeyManager { [weak statusItemController] in
            statusItemController?.showPopover(freshCapture: true)
        }
        hotkeyManager.start()
        self.hotkeyManager = hotkeyManager
    }
}
