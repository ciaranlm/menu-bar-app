import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let quickCapture = Self(
        "quickCapture",
        initial: KeyboardShortcuts.Shortcut(.space, modifiers: [.control, .shift])
    )
}
