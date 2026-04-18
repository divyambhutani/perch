import Foundation

struct TranscriptEvent: Codable, Sendable, Equatable {
    var type: String
    var sessionID: String
    var createdAt: Date
}
