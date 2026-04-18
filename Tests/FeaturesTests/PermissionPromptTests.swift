import Foundation
import Testing
@testable import Perch

@MainActor
struct PermissionPromptTests {
    @Test
    func approvalRemovesPendingPermission() throws {
        let store = SessionStore(
            currentFamiliar: SenecaFamiliar(),
            currentTheme: ThemePresets.defaultTheme
        )
        store.apply(
            event: HookEvent(
                kind: .permissionRequired(summary: "Approve", diffPreview: ""),
                receivedAt: .now
            )
        )

        let identifier = try #require(store.activeSession.pendingPermissions.first?.id)
        store.approvePermission(id: identifier)

        #expect(store.activeSession.pendingPermissions.isEmpty)
    }
}
