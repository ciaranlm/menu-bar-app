import Foundation

protocol NotesServicing {
    func save(_ text: String, appendToDailyNote: Bool) async throws -> SavedNoteResult
}

struct SavedNoteResult: Equatable {
    let title: String
    let appendedToDailyNote: Bool
}

enum NotesServiceError: LocalizedError, Equatable {
    case emptyText
    case automationPermissionDenied
    case notesUnavailable
    case appleScriptFailed(message: String, code: Int)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Enter a note before saving."
        case .automationPermissionDenied:
            return "Quick Notes needs permission to control Apple Notes. Open System Settings → Privacy & Security → Automation and allow Notes access."
        case .notesUnavailable:
            return "Apple Notes could not be opened. Make sure Notes is installed and try again."
        case let .appleScriptFailed(message, _):
            return message.isEmpty ? "Apple Notes could not create the note." : message
        }
    }
}

final class NotesService: NotesServicing {
    func save(_ text: String, appendToDailyNote: Bool) async throws -> SavedNoteResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw NotesServiceError.emptyText }

        let title = Self.title(from: text)
        let htmlBody = Self.htmlBody(from: text)
        let script: String
        let resultTitle: String

        if appendToDailyNote {
            resultTitle = Self.dailyNoteTitle()
            script = Self.appendToDailyNoteScript(title: resultTitle, htmlBody: htmlBody)
        } else {
            resultTitle = title
            script = Self.createNoteScript(title: title, htmlBody: htmlBody)
        }

        try await AppleScriptRunner.run(script)
        return SavedNoteResult(title: resultTitle, appendedToDailyNote: appendToDailyNote)
    }

    private static func title(from text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return firstLine.isEmpty ? "Quick Note" : String(firstLine.prefix(80))
    }

    private static func dailyNoteTitle(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "Quick Notes - \(formatter.string(from: date))"
    }

    private static func htmlBody(from text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        return "<div>\(escaped.replacingOccurrences(of: "\n", with: "<br>"))</div>"
    }

    private static func appleScriptLiteral(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    private static func createNoteScript(title: String, htmlBody: String) -> String {
        let titleLiteral = appleScriptLiteral(title)
        let bodyLiteral = appleScriptLiteral(htmlBody)

        return """
        -- Notes stores note bodies as HTML. The Swift layer escapes user text and converts
        -- line breaks to <br> tags before injecting it into these AppleScript literals.
        -- The first launch triggers macOS Automation consent for controlling Notes.
        tell application "Notes"
            make new note with properties {name:\(titleLiteral), body:\(bodyLiteral)}
        end tell
        """
    }

    private static func appendToDailyNoteScript(title: String, htmlBody: String) -> String {
        let titleLiteral = appleScriptLiteral(title)
        let bodyLiteral = appleScriptLiteral(htmlBody)

        return """
        -- Find today's Quick Notes note by title. If it does not exist, create it.
        -- If it exists, append a separator and the new escaped HTML body. Notes exposes
        -- existing note content as HTML through AppleScript, so appending HTML preserves
        -- the multiline formatting generated in Swift.
        tell application "Notes"
            set dailyTitle to \(titleLiteral)
            set newBody to \(bodyLiteral)
            set matchingNotes to every note whose name is dailyTitle

            if (count of matchingNotes) is 0 then
                make new note with properties {name:dailyTitle, body:newBody}
            else
                set targetNote to item 1 of matchingNotes
                set body of targetNote to (body of targetNote) & "<br><hr><br>" & newBody
            end if
        end tell
        """
    }
}
