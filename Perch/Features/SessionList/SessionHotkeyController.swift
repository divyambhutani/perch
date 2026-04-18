import Foundation
import KeyboardShortcuts

@MainActor
final class SessionHotkeyController {
    static let name = KeyboardShortcuts.Name("showSessionList")

    func register(action: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyUp(for: Self.name) {
            Task { @MainActor in
                action()
            }
        }
    }
}
