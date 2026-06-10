import Foundation

struct AppleScriptRunner {
    static func run(_ source: String) async throws {
        try await MainActor.run {
            guard let script = NSAppleScript(source: source) else {
                throw NotesServiceError.appleScriptFailed(message: "Could not prepare the AppleScript command.", code: 0)
            }

            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)

            if let errorInfo {
                let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
                let message = errorInfo[NSAppleScript.errorMessage] as? String ?? ""

                switch code {
                case -1743:
                    throw NotesServiceError.automationPermissionDenied
                case -600, -609:
                    throw NotesServiceError.notesUnavailable
                default:
                    if Self.isNotesResolutionFailure(message) {
                        throw NotesServiceError.notesUnavailable
                    }

                    throw NotesServiceError.appleScriptFailed(message: message, code: code)
                }
            }
        }
    }

    private static func isNotesResolutionFailure(_ message: String) -> Bool {
        let normalizedMessage = message.lowercased()
        return normalizedMessage.contains("com.apple.notes")
            && (normalizedMessage.contains("can’t get application")
                || normalizedMessage.contains("can't get application")
                || normalizedMessage.contains("application isn’t running")
                || normalizedMessage.contains("application isn't running"))
    }
}
