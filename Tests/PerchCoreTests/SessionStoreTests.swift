import Foundation
import Testing
@testable import Perch

@MainActor
struct SessionStoreTests {
    @Test
    func enteringPermissionStateRaisesAlert() {
        let store = makeStore()
        store.apply(
            event: HookEvent(
                kind: .permissionRequired(summary: "Approve", diffPreview: ""),
                receivedAt: .now
            )
        )

        #expect(store.activeSession.familiarState == .alert)
        #expect(store.activeSession.pendingPermissions.count == 1)
        #expect(store.sessionState == .needsAttention)
        #expect(store.pendingPermission != nil)
    }

    @Test
    func approvalClearsPendingAndReturnsToIdle() {
        let store = makeStore()
        store.apply(event: HookEvent(kind: .permissionRequired(summary: "Approve", diffPreview: ""), receivedAt: .now))
        let id = try! #require(store.pendingPermission?.id)

        store.approvePermission(id: id)

        #expect(store.pendingPermission == nil)
        #expect(store.sessionState == .idle)
    }

    @Test
    func hookEventBeforeMetricsMergesWithoutDroppingData() {
        let store = makeStore()
        store.apply(
            event: HookEvent(
                kind: .sessionStarted(sessionID: "abc", transcriptPath: "/tmp/t.jsonl", workingDirectory: "/tmp/project"),
                receivedAt: .now
            )
        )
        let metrics = SessionMetrics(
            sessionID: "abc",
            project: nil,
            cwd: "/tmp/project",
            startedAt: .now,
            lastActivity: .now,
            totalTokens: 500,
            totalCostUSD: 0.1,
            contextPercentage: 0.42,
            eventCount: 7
        )
        store.apply(metrics: metrics)

        #expect(store.activeSession.sessionIdentifier == "abc")
        #expect(store.activeSession.cwd == "/tmp/project")
        #expect(store.contextWindow.usedPercentage == 0.42)
    }

    @Test
    func derivedStateIsPureFunctionOfSnapshot() {
        var snapshot = SessionSnapshot.placeholder()

        snapshot.familiarState = .idle
        snapshot.pendingPermissions = []
        #expect(snapshot.derivedState == .idle)

        snapshot.familiarState = .working
        #expect(snapshot.derivedState == .active)

        snapshot.familiarState = .alert
        #expect(snapshot.derivedState == .needsAttention)

        snapshot.familiarState = .idle
        snapshot.pendingPermissions = [PermissionRequest(summary: "p", diffPreview: "")]
        #expect(snapshot.derivedState == .needsAttention)
    }

    private func makeStore() -> SessionStore {
        SessionStore(currentFamiliar: SenecaFamiliar(), currentTheme: ThemePresets.defaultTheme)
    }
}
