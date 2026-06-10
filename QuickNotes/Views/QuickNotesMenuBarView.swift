import AppKit
import SwiftUI

struct QuickNotesMenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    let closePopover: () -> Void

    @State private var text = ""
    @State private var isEditorFocused = false
    @State private var isSaving = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @State private var isContentVisible = false
    @State private var handledQuickCaptureRequestID: UUID?
    @State private var clearSuccessTask: Task<Void, Never>?

    init(closePopover: @escaping () -> Void = {}) {
        self.closePopover = closePopover
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            editor
            controls
            statusMessage
        }
        .padding(16)
        .frame(width: 360)
        .opacity(isContentVisible ? 1 : 0)
        .scaleEffect(isContentVisible ? 1 : 0.97, anchor: .top)
        .animation(.easeOut(duration: 0.16), value: isContentVisible)
        .task {
            isContentVisible = true
            handleFreshCaptureRequestIfNeeded()
        }
        .onChange(of: appState.quickCaptureRequestID) { _, _ in
            handleFreshCaptureRequestIfNeeded()
        }
        .onDisappear {
            isContentVisible = false
            clearSuccessTask?.cancel()
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
        NoteEditor(
            text: $text,
            isFocused: $isEditorFocused,
            onSave: { Task { await saveNote() } },
            onCancel: closePopover
        )
        .frame(height: 120)
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
                Text("⌘↩ Save · Esc Close")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                .disabled(isSaving || trimmedText.isEmpty)
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
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleFreshCaptureRequestIfNeeded() {
        guard handledQuickCaptureRequestID != appState.quickCaptureRequestID else {
            focusEditorAfterPopoverAppears()
            return
        }

        handledQuickCaptureRequestID = appState.quickCaptureRequestID
        prepareFreshCapture()
    }

    private func prepareFreshCapture() {
        clearSuccessTask?.cancel()
        text = ""
        successMessage = nil
        errorMessage = nil
        isEditorFocused = false
        focusEditorAfterPopoverAppears()
    }

    private func saveNote() async {
        let noteText = trimmedText
        guard !noteText.isEmpty, !isSaving else { return }

        isSaving = true
        successMessage = nil
        errorMessage = nil
        clearSuccessTask?.cancel()

        do {
            _ = try await appState.notesService.save(noteText, appendToDailyNote: appState.appendToDailyNote)
            text = ""
            withAnimation(.easeOut(duration: 0.16)) {
                successMessage = "Saved ✓"
            }
            scheduleSuccessMessageClear()
            focusEditorAfterPopoverAppears()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSaving = false
    }

    private func scheduleSuccessMessageClear() {
        clearSuccessTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.16)) {
                successMessage = nil
            }
        }
    }

    private func focusEditorAfterPopoverAppears() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            isEditorFocused = true
        }
    }
}

private struct NoteEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    let onSave: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = KeyboardHandlingTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.textContainerInset = NSSize(width: 6, height: 9)
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text
        textView.onSave = onSave
        textView.onCancel = onCancel

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true

        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? KeyboardHandlingTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        textView.font = .preferredFont(forTextStyle: .body)
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.onSave = onSave
        textView.onCancel = onCancel

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
                textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
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

private final class KeyboardHandlingTextView: NSTextView {
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if (event.keyCode == 36 || event.keyCode == 76), event.modifierFlags.contains(.command) {
            onSave?()
            return
        }

        if event.keyCode == 53 {
            onCancel?()
            return
        }

        super.keyDown(with: event)
    }
}

#Preview {
    QuickNotesMenuBarView()
        .environmentObject(AppState())
}
