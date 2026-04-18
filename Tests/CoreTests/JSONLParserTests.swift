import Testing
@testable import Perch

struct JSONLParserTests {
    @Test
    func rejectsMalformedLines() {
        let parser = JSONLParser()
        let contents = """
        {"type":"assistant","sessionID":"abc","createdAt":"2026-04-18T00:00:00Z"}
        malformed
        """

        #expect(throws: JSONLError.malformedLine("malformed")) {
            try parser.parse(contents: contents)
        }
    }
}
