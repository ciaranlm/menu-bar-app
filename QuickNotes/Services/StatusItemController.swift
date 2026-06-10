import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var settingsWindowController: NSWindowController?

    init(appState: AppState) {
        self.appState = appState
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        configurePopover()
    }

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover(freshCapture: false)
        }
    }

    func showPopover(freshCapture: Bool) {
        if freshCapture {
            appState.startFreshCapture()
        }

        guard let button = statusItem.button else { return }

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func closePopover() {
        popover.performClose(nil)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "Wingit")
        button.action = #selector(statusItemClicked)
        button.target = self
        button.toolTip = "Wingit Quick Notes"
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 360, height: 280)
        popover.contentViewController = NSHostingController(
            rootView: QuickNotesMenuBarView(
                closePopover: { [weak self] in
                    self?.closePopover()
                },
                openSettings: { [weak self] in
                    self?.openSettings()
                }
            )
            .environmentObject(appState)
        )
    }

    private func openSettings() {
        closePopover()

        let windowController: NSWindowController
        if let existingWindowController = settingsWindowController {
            windowController = existingWindowController
        } else {
            windowController = makeSettingsWindowController()
            settingsWindowController = windowController
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindowController() -> NSWindowController {
        let settingsView = SettingsView()
            .environmentObject(appState)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Wingit Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }

    @objc private func statusItemClicked() {
        togglePopover()
    }
}
