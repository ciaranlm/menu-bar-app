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

            Section("Shortcuts") {
                Text("Press Command-Return while the popover is open to save the current note.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
        .navigationTitle("Wingit Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
