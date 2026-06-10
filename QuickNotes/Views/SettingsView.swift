import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection("Saving") {
                Toggle("Append new entries to a daily note", isOn: $appState.appendToDailyNote)
                Text("Daily notes are named “Wingit - yyyy-MM-dd”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            settingsSection("Startup") {
                Toggle("Launch Wingit at login", isOn: Binding(
                    get: { appState.launchAtLoginEnabled },
                    set: { appState.setLaunchAtLogin($0) }
                ))
            }

            settingsSection("Keyboard Shortcuts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Open Quick Notes: Control-Shift-Space")
                    Text("Command-Return saves while the popover is open. Escape closes it without saving.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 460, minHeight: 300, alignment: .topLeading)
        .navigationTitle("Wingit Settings")
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
