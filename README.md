# Wingit

Wingit is a native macOS 14+ menu bar app built with SwiftUI. It lets you write a short note in a compact menu bar popover and save it directly into Apple Notes.

## Running in Xcode

1. Open `QuickNotes.xcodeproj` in Xcode 15 or newer.
2. Select the **Wingit** scheme.
3. In **Signing & Capabilities**, choose your development team and update the bundle identifier if needed.
4. Build and run with **Product → Run** (`⌘R`).
5. Click the `bird.fill` SF Symbol in the macOS menu bar, type a note, and choose **Save to Notes**.
6. The first save will prompt for Automation permission to control Notes. Allow it.

## Architecture

- `QuickNotesApp` is the SwiftUI entry point and declares the `MenuBarExtra` scene.
- `QuickNotesMenuBarView` renders the popover UI and owns transient editor state.
- `NotesService` derives note titles, converts plain text to safe Notes HTML, and builds the AppleScript commands.
- `AppleScriptRunner` executes AppleScript and maps common Apple Event failures to user-friendly errors.
- `AppState` stores app-wide settings, including daily-note mode and launch-at-login state.
- `LaunchAtLoginManager` wraps `SMAppService.mainApp`.

## Permissions

Wingit controls Apple Notes through Apple Events. macOS will ask for Automation consent the first time the app tries to save a note. If access is denied, enable it in **System Settings → Privacy & Security → Automation**.

The app includes the `NSAppleEventsUsageDescription` purpose string and the Apple Events sandbox entitlement required for a sandboxed app.

## Packaging and distribution

1. Set a unique bundle identifier and signing team in Xcode.
2. Archive with **Product → Archive**.
3. For direct distribution, export a Developer ID signed app and notarize it through Xcode Organizer.
4. For the Mac App Store, keep App Sandbox enabled and verify Apple Events usage against App Store Review requirements.
5. Ship the notarized `.app` in a signed `.dmg` or `.pkg` installer.


