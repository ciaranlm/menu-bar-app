import AppKit
import Carbon.HIToolbox
import Combine

private let wingitHotKeySignature = OSType(0x574E4754) // "WNGT"
private let wingitHotKeyID = UInt32(1)

@MainActor
final class HotkeyManager: ObservableObject {
    private static weak var activeManager: HotkeyManager?

    private let openQuickCapture: @MainActor () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?

    init(openQuickCapture: @escaping @MainActor () -> Void) {
        self.openQuickCapture = openQuickCapture
    }

    func start() {
        stop()
        Self.activeManager = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        _ = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr,
                      hotKeyID.signature == wingitHotKeySignature,
                      hotKeyID.id == wingitHotKeyID
                else {
                    return status
                }

                Task { @MainActor in
                    HotkeyManager.activeManager?.openQuickCapture()
                }

                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        var hotKeyID = EventHotKeyID(signature: wingitHotKeySignature, id: wingitHotKeyID)
        _ = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKey
        )
    }

    func stop() {
        if let hotKey {
            _ = UnregisterEventHotKey(hotKey)
            self.hotKey = nil
        }

        if let eventHandler {
            _ = RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        if Self.activeManager === self {
            Self.activeManager = nil
        }
    }
}
