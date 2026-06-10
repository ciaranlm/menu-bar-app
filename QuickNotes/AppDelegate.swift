import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep the app out of the Dock even if Info.plist is changed while debugging.
        NSApp.setActivationPolicy(.accessory)
    }
}
