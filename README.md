# Wingit

Wingit is a lightweight macOS menu bar companion for capturing quick thoughts into Apple Notes without opening the Notes app first. It keeps a small writing surface one click—or one keyboard shortcut—away, then sends the note to Notes through the system's Apple Events automation.

## What it does

- **Fast menu bar capture**: Wingit lives in the macOS menu bar with a pigeon status icon, keeping note entry available without adding a Dock app or full window workflow.
- **Apple Notes integration**: Notes are saved directly into Apple Notes, using the first line of your text as the note title when creating a standalone note.
- **Daily-note mode**: An optional setting appends new entries to a daily note named `Wingit - yyyy-MM-dd`, creating that note automatically when needed.
- **Keyboard-first workflow**: `Control-Shift-Space` opens a fresh capture popover, `Command-Return` saves, and `Escape` closes the popover without saving.
- **Launch at login**: Wingit can be configured to start automatically when you sign in.
- **Native macOS experience**: The app is built with SwiftUI and AppKit menu bar APIs, including a compact transient popover and a dedicated settings window.

## How it works

Wingit converts the note text into safe HTML, preserves line breaks, and asks Apple Notes to create or update the target note. Because this uses Apple Events, macOS controls access through Automation privacy permissions. On first save, the system may ask whether Wingit can control Notes; granting access lets the app write captured notes into Apple Notes.

## Privacy

Wingit is designed around local capture into Apple Notes. The app stores only small preference values locally, such as whether daily-note mode and launch-at-login are enabled. Note content is passed to Apple Notes on your Mac and is not sent to a separate Wingit service.

## App structure

- `QuickNotesApp` provides the SwiftUI app entry point and settings scene.
- `AppDelegate` keeps the app menu-bar-only, creates the status item, and starts the global hotkey handler.
- `StatusItemController` owns the menu bar icon, popover, and settings window.
- `QuickNotesMenuBarView` renders the quick-capture editor, save controls, and status messages.
- `SettingsView` exposes saving, startup, and shortcut details.
- `NotesService` prepares note titles and HTML bodies, then builds the AppleScript used to create or append notes.
- `AppleScriptRunner` executes the AppleScript and turns common automation failures into user-facing errors.
