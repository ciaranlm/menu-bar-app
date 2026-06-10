import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Saving") {
                Toggle("Append new entries to a daily note", isOn: $appState.appendToDailyNote)
                Text("Daily notes are named “Wingit - yyyy-MM-dd”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch Wingit at login", isOn: Binding(
                    get: { appState.launchAtLoginEnabled },
                    set: { appState.setLaunchAtLogin($0) }
                ))
            }

            Section("Keyboard Shortcuts") {
                KeyboardShortcuts.Recorder("Open Quick Notes:", name: .quickCapture)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Default: Control-Shift-Space")
                    Text("Command-Return saves while the popover is open. Escape closes it without saving.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
        .navigationTitle("Wingit Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
