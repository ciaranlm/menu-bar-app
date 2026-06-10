import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var appendToDailyNote: Bool {
        didSet { UserDefaults.standard.set(appendToDailyNote, forKey: Self.appendToDailyNoteKey) }
    }

    @Published var launchAtLoginEnabled: Bool = LaunchAtLoginManager.isEnabled

    let notesService: NotesServicing

    private static let appendToDailyNoteKey = "appendToDailyNote"

    init(notesService: NotesServicing = NotesService()) {
        self.notesService = notesService
        appendToDailyNote = UserDefaults.standard.object(forKey: Self.appendToDailyNoteKey) as? Bool ?? false
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        } catch {
            // Revert the toggle if ServiceManagement refuses the change.
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        }
    }
}
