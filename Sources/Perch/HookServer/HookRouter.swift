import Foundation

struct HookRouter {
    struct HookPayload: Codable, Sendable, Equatable {
        let type: String?
        let hookEventName: String?
        let sessionID: String?
        let transcriptPath: String?
        let workingDirectory: String?
        let summary: String?
        let diffPreview: String?
        let percentage: Double?
        let message: String?
        let toolName: String?
        let toolInput: ToolInput?
        let reason: String?

        enum CodingKeys: String, CodingKey {
            case type
            case hookEventName = "hook_event_name"
            case sessionID = "session_id"
            case transcriptPath = "transcript_path"
            case workingDirectory = "cwd"
            case summary
            case diffPreview
            case percentage
            case message
            case toolName = "tool_name"
            case toolInput = "tool_input"
            case reason
        }

        struct ToolInput: Codable, Sendable, Equatable {
            let command: String?
            let filePath: String?

            enum CodingKeys: String, CodingKey {
                case command
                case filePath = "file_path"
            }
        }
    }

    func route(_ request: HookRequestParser.ParsedRequest) throws -> HookEvent {
        let payload = try JSONDecoder().decode(HookPayload.self, from: request.body)

        let kind: HookEvent.Kind
        switch payload.hookEventName ?? payload.type {
        case "SessionStart":
            kind = .sessionStarted(
                sessionID: payload.sessionID ?? UUID().uuidString,
                transcriptPath: payload.transcriptPath,
                workingDirectory: payload.workingDirectory
            )
        case "SessionEnd":
            kind = .sessionEnded(reason: payload.reason)
        case "Notification":
            let message = payload.message ?? payload.summary ?? "Notification received."
            if message.localizedCaseInsensitiveContains("permission") {
                kind = .permissionRequired(
                    summary: message,
                    diffPreview: payload.diffPreview ?? ""
                )
            } else {
                kind = .notification(message: message)
            }
        case "PreToolUse":
            kind = .toolStarted(
                name: payload.toolName ?? "tool",
                commandPreview: payload.toolInput?.command ?? payload.toolInput?.filePath
            )
        case "PostToolUse":
            kind = .toolFinished(name: payload.toolName ?? "tool")
        case "UserPromptSubmit":
            kind = .promptSubmitted(sessionID: payload.sessionID)
        case "Stop":
            kind = .stopped(sessionID: payload.sessionID)
        case "SubagentStop":
            kind = .subagentStopped(sessionID: payload.sessionID)
        case "PreCompact":
            kind = .preCompact(sessionID: payload.sessionID)
        case "permission_required":
            kind = .permissionRequired(
                summary: payload.summary ?? "Permission required.",
                diffPreview: payload.diffPreview ?? ""
            )
        case "work_started":
            kind = .workStarted
        case "work_finished":
            kind = .workFinished
        case "session_watching":
            kind = .sessionWatching
        case "context_window":
            kind = .contextWindow(percentage: payload.percentage ?? 0)
        default:
            kind = .sessionWatching
        }

        let headers = request.headers
        let terminalPID = headers["x-perch-terminal-pid"].flatMap { Int32($0) }
        let terminalBundleID = headers["x-perch-terminal-bundle"].flatMap { value in
            value.isEmpty ? nil : value
        }

        return HookEvent(
            kind: kind,
            receivedAt: .now,
            sessionID: payload.sessionID,
            cwd: payload.workingDirectory,
            transcriptPath: payload.transcriptPath,
            terminalPID: terminalPID,
            terminalBundleID: terminalBundleID
        )
    }
}
