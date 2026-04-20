import Foundation

struct HookEvent: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case sessionStarted(sessionID: String, transcriptPath: String?, workingDirectory: String?)
        case sessionEnded(reason: String?)
        case notification(message: String)
        case toolStarted(name: String, commandPreview: String?)
        case toolFinished(name: String)
        case permissionRequired(summary: String, diffPreview: String)
        case workStarted
        case workFinished
        case sessionWatching
        case contextWindow(percentage: Double)
        case promptSubmitted(sessionID: String?)
        case stopped(sessionID: String?)
        case subagentStopped(sessionID: String?)
        case preCompact(sessionID: String?)
    }

    var kind: Kind
    var receivedAt: Date
    var sessionID: String?
    var cwd: String?
    var transcriptPath: String?
    var terminalPID: Int32?
    var terminalBundleID: String?

    init(
        kind: Kind,
        receivedAt: Date,
        sessionID: String? = nil,
        cwd: String? = nil,
        transcriptPath: String? = nil,
        terminalPID: Int32? = nil,
        terminalBundleID: String? = nil
    ) {
        self.kind = kind
        self.receivedAt = receivedAt
        self.sessionID = sessionID
        self.cwd = cwd
        self.transcriptPath = transcriptPath
        self.terminalPID = terminalPID
        self.terminalBundleID = terminalBundleID
    }
}
