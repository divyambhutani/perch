import Foundation
import Testing
@testable import Perch

@MainActor
struct SessionStoreDiscoveryIntegrationTests {
    @Test
    func discoveredSessionsOrderedByLastActivityDesc() {
        let store = makeStore()
        let older = DiscoveredSession(
            jsonlURL: URL(fileURLWithPath: "/tmp/older.jsonl"),
            sessionID: "older",
            projectDirectory: "proj-a",
            lastActivity: Date(timeIntervalSinceNow: -120)
        )
        let newer = DiscoveredSession(
            jsonlURL: URL(fileURLWithPath: "/tmp/newer.jsonl"),
            sessionID: "newer",
            projectDirectory: "proj-b",
            lastActivity: .now
        )

        store.apply(discoveredSessions: [older, newer])

        #expect(store.activeSession.sessionIdentifier == "newer")
        #expect(store.sessions.map(\.sessionIdentifier) == ["newer", "older"])
    }

    @Test
    func metricsApplyReordersWhenActivityChanges() {
        let store = makeStore()
        let a = DiscoveredSession(
            jsonlURL: URL(fileURLWithPath: "/tmp/a.jsonl"),
            sessionID: "a",
            projectDirectory: "proj-a",
            lastActivity: Date(timeIntervalSinceNow: -30)
        )
        let b = DiscoveredSession(
            jsonlURL: URL(fileURLWithPath: "/tmp/b.jsonl"),
            sessionID: "b",
            projectDirectory: "proj-b",
            lastActivity: Date(timeIntervalSinceNow: -10)
        )
        store.apply(discoveredSessions: [a, b])
        #expect(store.activeSession.sessionIdentifier == "b")

        let refreshed = SessionMetrics(
            sessionID: "a",
            project: nil,
            cwd: "/tmp/proj-a",
            startedAt: nil,
            lastActivity: .now,
            totalTokens: 0,
            totalCostUSD: 0,
            contextPercentage: 0.1,
            eventCount: 1
        )
        store.apply(metrics: refreshed)

        #expect(store.activeSession.sessionIdentifier == "a")
    }

    @Test
    func discoveredSessionsStripPlaceholder() {
        let store = makeStore()
        #expect(store.sessions.contains(where: { $0.isPlaceholder }))

        let discovered = DiscoveredSession(
            jsonlURL: URL(fileURLWithPath: "/tmp/d.jsonl"),
            sessionID: "d",
            projectDirectory: "proj",
            lastActivity: .now
        )
        store.apply(discoveredSessions: [discovered])

        #expect(store.sessions.contains(where: { $0.isPlaceholder }) == false)
        #expect(store.sessions.count == 1)
        #expect(store.activeSession.sessionIdentifier == "d")
    }

    private func makeStore() -> SessionStore {
        SessionStore(currentFamiliar: SenecaFamiliar(), currentTheme: ThemePresets.defaultTheme)
    }
}
