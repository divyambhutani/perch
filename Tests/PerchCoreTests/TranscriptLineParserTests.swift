import Foundation
import Testing
@testable import Perch

struct TranscriptLineParserTests {
    @Test
    func capturesUserPromptFromTextBlock() {
        let line = #"""
        {"type":"user","message":{"role":"user","content":[{"type":"text","text":"read the spec and summarize"}]},"timestamp":"2026-04-18T10:00:00Z"}
        """#
        var turn = LiveTurn.empty
        TranscriptLineParser.apply(line: line, into: &turn)
        #expect(turn.lastUserPrompt == "read the spec and summarize")
        #expect(turn.activeToolName == nil)
    }

    @Test
    func capturesUserPromptFromStringContent() {
        let line = #"{"type":"user","message":{"role":"user","content":"hi there"}}"#
        var turn = LiveTurn.empty
        TranscriptLineParser.apply(line: line, into: &turn)
        #expect(turn.lastUserPrompt == "hi there")
    }

    @Test
    func capturesActiveToolFromAssistantMessage() {
        let line = #"""
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"running search"},{"type":"tool_use","name":"Grep","input":{"pattern":"foo.*bar"}}]}}
        """#
        var turn = LiveTurn.empty
        TranscriptLineParser.apply(line: line, into: &turn)
        #expect(turn.activeToolName == "Grep")
        #expect(turn.activeToolPreview == "foo.*bar")
    }

    @Test
    func clearsActiveToolOnToolResult() {
        var turn = LiveTurn.empty
        let assistantLine = #"""
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","input":{"command":"ls -la"}}]}}
        """#
        let resultLine = #"""
        {"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"abc","content":"files"}]}}
        """#
        TranscriptLineParser.apply(line: assistantLine, into: &turn)
        #expect(turn.activeToolName == "Bash")
        TranscriptLineParser.apply(line: resultLine, into: &turn)
        #expect(turn.activeToolName == nil)
        #expect(turn.activeToolPreview == nil)
    }

    @Test
    func newUserPromptResetsActiveTool() {
        var turn = LiveTurn.empty
        turn.activeToolName = "Grep"
        turn.activeToolPreview = "stale"
        let line = #"""
        {"type":"user","message":{"role":"user","content":[{"type":"text","text":"new request"}]}}
        """#
        TranscriptLineParser.apply(line: line, into: &turn)
        #expect(turn.lastUserPrompt == "new request")
        #expect(turn.activeToolName == nil)
    }

    @Test
    func truncatesLongToolPreview() {
        let longPattern = String(repeating: "a", count: 200)
        let line = #"""
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Grep","input":{"pattern":"\#(longPattern)"}}]}}
        """#
        var turn = LiveTurn.empty
        TranscriptLineParser.apply(line: line, into: &turn)
        #expect(turn.activeToolPreview?.hasSuffix("…") == true)
        #expect((turn.activeToolPreview?.count ?? 0) <= 60)
    }

    @Test
    func ignoresUnknownLineType() {
        var turn = LiveTurn.empty
        TranscriptLineParser.apply(line: #"{"type":"summary","content":"x"}"#, into: &turn)
        #expect(turn == .empty)
    }
}
