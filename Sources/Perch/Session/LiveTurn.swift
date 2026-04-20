import Foundation

struct LiveTurn: Sendable, Equatable {
    var lastUserPrompt: String?
    var activeToolName: String?
    var activeToolPreview: String?
    var turnStartedAt: Date?

    static let empty = LiveTurn()
}
