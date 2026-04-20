import Foundation
import Testing
@testable import Perch

struct HookRouterTests {
    @Test
    func routesStopEvent() throws {
        let event = try route(body: #"{"hook_event_name":"Stop","session_id":"abc"}"#)
        #expect(event.kind == .stopped(sessionID: "abc"))
    }

    @Test
    func routesUserPromptSubmit() throws {
        let event = try route(body: #"{"hook_event_name":"UserPromptSubmit","session_id":"xyz"}"#)
        #expect(event.kind == .promptSubmitted(sessionID: "xyz"))
    }

    @Test
    func routesSubagentStop() throws {
        let event = try route(body: #"{"hook_event_name":"SubagentStop","session_id":"s1"}"#)
        #expect(event.kind == .subagentStopped(sessionID: "s1"))
    }

    @Test
    func routesPreCompact() throws {
        let event = try route(body: #"{"hook_event_name":"PreCompact","session_id":"s2"}"#)
        #expect(event.kind == .preCompact(sessionID: "s2"))
    }

    @Test
    func routesPreToolUseWithCommandPreview() throws {
        let event = try route(
            body: #"{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}"#
        )
        #expect(event.kind == .toolStarted(name: "Bash", commandPreview: "ls -la"))
    }

    @Test
    func routesSessionStartWithPaths() throws {
        let event = try route(
            body: #"{"hook_event_name":"SessionStart","session_id":"s","transcript_path":"/tmp/t.jsonl","cwd":"/tmp"}"#
        )
        #expect(
            event.kind == .sessionStarted(sessionID: "s", transcriptPath: "/tmp/t.jsonl", workingDirectory: "/tmp")
        )
    }

    @Test
    func capturesTerminalHeaders() throws {
        let parsed = HookRequestParser.ParsedRequest(
            method: "POST",
            path: "/hooks",
            headers: [
                "x-perch-terminal-pid": "4321",
                "x-perch-terminal-bundle": "com.googlecode.iterm2"
            ],
            body: Data(#"{"hook_event_name":"Stop","session_id":"a"}"#.utf8)
        )
        let event = try HookRouter().route(parsed)
        #expect(event.terminalPID == 4321)
        #expect(event.terminalBundleID == "com.googlecode.iterm2")
    }

    private func route(body: String) throws -> HookEvent {
        let parsed = HookRequestParser.ParsedRequest(
            method: "POST",
            path: "/hooks",
            headers: [:],
            body: Data(body.utf8)
        )
        return try HookRouter().route(parsed)
    }
}
