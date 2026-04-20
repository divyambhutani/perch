import Foundation
import Testing
@testable import Perch

struct JSONLParserTests {
    @Test
    func rejectsMalformedLines() {
        let parser = JSONLParser()
        let contents = """
        {"type":"assistant","session_id":"abc","created_at":"2026-04-18T00:00:00Z"}
        malformed
        """

        #expect(throws: JSONLError.malformedLine("malformed")) {
            try parser.parse(contents: contents)
        }
    }

    @Test
    func preservesPartialTrailingLine() throws {
        let parser = JSONLParser()
        let chunk = Data(#"{"type":"assistant","session_id":"abc","created_at":"2026-04-18T00:00:00Z"}"#.utf8)
            + Data("\n{\"type\":\"tool\",\"session_id\":".utf8)

        let parsed = try parser.parseStream(chunk, flushTrailing: false)

        #expect(parsed.events.count == 1)
        #expect(parsed.remainder.count > 0)
    }

    @Test
    func resumesOnceRemainderCompletes() throws {
        let parser = JSONLParser()
        let first = Data("{\"type\":\"tool\",\"session_id\":".utf8)
        let second = Data("\"abc\"}\n".utf8)

        var parsed = try parser.parseStream(first, flushTrailing: false)
        #expect(parsed.events.isEmpty)

        var buffer = parsed.remainder
        buffer.append(second)
        parsed = try parser.parseStream(buffer, flushTrailing: false)

        #expect(parsed.events.count == 1)
        #expect(parsed.events[0].sessionID == "abc")
    }
}
