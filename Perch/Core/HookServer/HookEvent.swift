import Foundation

struct HookEvent: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case sessionStarted(sessionID: String, transcriptPath: String?, workingDirectory: String?)
        case sessionEnded(reason: String?)
        case notification(message: String)
        case toolStarted(name: String)
        case toolFinished(name: String)
        case permissionRequired(summary: String, diffPreview: String)
        case workStarted
        case workFinished
        case sessionWatching
        case contextWindow(percentage: Double)
    }

    var kind: Kind
    var receivedAt: Date
}
