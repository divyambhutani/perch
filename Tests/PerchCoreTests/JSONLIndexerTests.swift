import Foundation
import Testing
@testable import Perch

@MainActor
struct JSONLIndexerTests {
    @Test
    func indexesValidEvents() throws {
        let indexer = JSONLIndexer()
        let contents = """
        {"type":"assistant","session_id":"abc","created_at":"2026-04-18T00:00:00Z"}
        {"type":"tool","session_id":"abc","created_at":"2026-04-18T00:01:00Z"}
        """

        let events = try indexer.index(contents: contents)

        #expect(events.count == 2)
        #expect(events[0].sessionID == "abc")
    }

    @Test
    func foldsEventsIntoSessionMetrics() throws {
        let indexer = JSONLIndexer()
        let contents = """
        {"type":"assistant","session_id":"abc","created_at":"2026-04-18T00:00:00Z","input_tokens":100,"output_tokens":50,"cwd":"/tmp/project"}
        {"type":"tool","session_id":"abc","created_at":"2026-04-18T00:01:00Z","input_tokens":10,"output_tokens":5,"cost_usd":0.01}
        {"type":"assistant","session_id":"xyz","created_at":"2026-04-18T00:02:00Z","input_tokens":20,"output_tokens":10}
        """

        _ = try indexer.index(contents: contents)
        let abc = try #require(indexer.metrics(for: "abc"))

        #expect(abc.totalTokens == 165)
        #expect(abc.eventCount == 2)
        #expect(abc.cwd == "/tmp/project")
        #expect(indexer.allMetrics().count == 2)
    }

    @Test
    func resetClearsAccumulatedMetrics() throws {
        let indexer = JSONLIndexer()
        _ = try indexer.index(contents: #"{"type":"assistant","session_id":"abc"}"#)
        indexer.reset()
        #expect(indexer.metrics(for: "abc") == nil)
    }
}
