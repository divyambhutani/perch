import Testing
@testable import Perch

@MainActor
struct JSONLIndexerTests {
    @Test
    func indexesValidEvents() throws {
        let indexer = JSONLIndexer()
        let contents = """
        {"type":"assistant","sessionID":"abc","createdAt":"2026-04-18T00:00:00Z"}
        {"type":"tool","sessionID":"abc","createdAt":"2026-04-18T00:01:00Z"}
        """

        let events = try indexer.index(contents: contents)

        #expect(events.count == 2)
        #expect(events[0].sessionID == "abc")
    }
}
