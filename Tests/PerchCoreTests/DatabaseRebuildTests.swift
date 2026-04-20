import Foundation
import Testing
@testable import Perch

@MainActor
struct DatabaseRebuildTests {
    @Test
    func rebuildFromJSONLYieldsIdenticalRows() async throws {
        let fixture = """
        {"type":"assistant","session_id":"abc","created_at":"2026-04-18T00:00:00Z","input_tokens":100,"output_tokens":50,"cwd":"/tmp/alpha"}
        {"type":"tool","session_id":"abc","created_at":"2026-04-18T00:01:00Z","input_tokens":10,"output_tokens":5}
        {"type":"assistant","session_id":"xyz","created_at":"2026-04-18T00:02:00Z","input_tokens":30,"output_tokens":15,"cwd":"/tmp/beta"}
        """

        let firstRows = try await indexAndPersist(fixture: fixture)
        let secondRows = try await indexAndPersist(fixture: fixture)

        #expect(firstRows == secondRows)
        #expect(firstRows.count == 2)
    }

    @Test
    func upsertReplacesExistingRow() async throws {
        let db = try DatabaseManager(location: .memory)
        let a = SessionRecord(id: "abc", state: "watching", contextPct: 0.2, tokenTotal: 10)
        let b = SessionRecord(id: "abc", state: "idle", contextPct: 0.5, tokenTotal: 99)

        try await db.upsert(a)
        try await db.upsert(b)

        let rows = try await db.fetchSessions()
        #expect(rows.count == 1)
        #expect(rows[0].tokenTotal == 99)
        #expect(rows[0].state == "idle")
    }

    private func indexAndPersist(fixture: String) async throws -> [SessionRecord] {
        let indexer = JSONLIndexer()
        _ = try indexer.index(contents: fixture)
        let db = try DatabaseManager(location: .memory)
        let records = indexer.allMetrics()
            .map { SessionRecord(metrics: $0) }
            .sorted { $0.id < $1.id }
        try await db.upsert(records)
        return try await db.fetchSessions().sorted { $0.id < $1.id }
    }
}
