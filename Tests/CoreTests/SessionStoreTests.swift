import Foundation
import Testing
@testable import Perch

@MainActor
struct SessionStoreTests {
    @Test
    func enteringPermissionStateRaisesAlert() {
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

        #expect(store.activeSession.familiarState == .alert)
        #expect(store.activeSession.pendingPermissions.count == 1)
    }
}
