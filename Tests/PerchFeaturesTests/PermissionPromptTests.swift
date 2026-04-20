import Foundation
import Testing
@testable import Perch

@MainActor
struct PermissionPromptTests {
    @Test
    func approvalRemovesPendingPermission() throws {
        let store = makeStore()
        store.apply(
            event: HookEvent(
                kind: .permissionRequired(summary: "Approve", diffPreview: ""),
                receivedAt: .now
            )
        )
        let identifier = try #require(store.pendingPermission?.id)

        store.approvePermission(id: identifier)

        #expect(store.pendingPermission == nil)
    }

    @Test
    func denialRemovesPendingPermission() throws {
        let store = makeStore()
        store.apply(
            event: HookEvent(
                kind: .permissionRequired(summary: "Deny me", diffPreview: ""),
                receivedAt: .now
            )
        )
        let identifier = try #require(store.pendingPermission?.id)

        store.denyPermission(id: identifier)

        #expect(store.pendingPermission == nil)
        #expect(store.sessionState == .idle)
    }

    private func makeStore() -> SessionStore {
        SessionStore(currentFamiliar: SenecaFamiliar(), currentTheme: ThemePresets.defaultTheme)
    }
}
