import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showSessionList = KeyboardShortcuts.Name(
        "showSessionList",
        default: .init(.c, modifiers: [.control, .command])
    )
}

@MainActor
public final class SessionHotkeyController {
    public init() {}

    public func register(action: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .showSessionList) {
            Task { @MainActor in
                action()
            }
        }
    }

    public func unregister() {
        KeyboardShortcuts.disable(.showSessionList)
    }
}
