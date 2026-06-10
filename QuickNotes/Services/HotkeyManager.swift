import Combine
import Foundation
import KeyboardShortcuts

@MainActor
final class HotkeyManager: ObservableObject {
    private let openQuickCapture: @MainActor () -> Void

    init(openQuickCapture: @escaping @MainActor () -> Void) {
        self.openQuickCapture = openQuickCapture
    }

    func start() {
        KeyboardShortcuts.onKeyUp(for: .quickCapture) { [weak self] in
            Task { @MainActor in
                self?.openQuickCapture()
            }
        }
    }
}
