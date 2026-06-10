import AppKit
import SwiftUI

struct QuickNotesMenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    @State private var text = ""
    @State private var isEditorFocused = false
    @State private var isSaving = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            editor
            controls
            statusMessage
        }
        .padding(16)
        .frame(width: 360)
        .task {
            focusEditorAfterPopoverAppears()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bird.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text("Wingit")
                .font(.headline)

            Spacer()

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .help("Open Settings")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private var editor: some View {
        NoteEditor(text: $text, isFocused: $isEditorFocused)
            .frame(height: 180)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type a note…")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .allowsHitTesting(false)
                }
            }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Append to today’s daily note", isOn: $appState.appendToDailyNote)
                .toggleStyle(.checkbox)

            HStack {
                Spacer()

                Button {
                    Task { await saveNote() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Save to Notes")
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let successMessage {
            Label(successMessage, systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.green)
        } else if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func saveNote() async {
        let noteText = text
        isSaving = true
        successMessage = nil
        errorMessage = nil

        do {
            let result = try await appState.notesService.save(noteText, appendToDailyNote: appState.appendToDailyNote)
            text = ""
            successMessage = result.appendedToDailyNote
                ? "Added to \(result.title)."
                : "Saved \(result.title)."
            focusEditorAfterPopoverAppears()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSaving = false
    }

    private func focusEditorAfterPopoverAppears() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            isEditorFocused = true
        }
    }
}

private struct NoteEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.textContainerInset = NSSize(width: 6, height: 9)
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        textView.font = .preferredFont(forTextStyle: .body)
        textView.insertionPointColor = NSColor.controlAccentColor

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            isFocused = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isFocused = false
        }
    }
}

#Preview {
    QuickNotesMenuBarView()
        .environmentObject(AppState())
}
