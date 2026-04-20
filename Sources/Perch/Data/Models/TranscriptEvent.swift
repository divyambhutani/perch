import Foundation

struct TranscriptEvent: Codable, Sendable, Equatable {
    var type: String
    var subtype: String?
    var sessionID: String?
    var createdAt: Date?
    var model: String?
    var costUSD: Double?
    var durationMs: Int?
    var inputTokens: Int?
    var outputTokens: Int?
    var cacheReadTokens: Int?
    var cacheWriteTokens: Int?
    var message: TranscriptMessage?
    var cwd: String?
    var toolName: String?

    struct TranscriptMessage: Codable, Sendable, Equatable {
        var role: String?
        var content: String?
    }

    var totalTokens: Int {
        (inputTokens ?? 0) + (outputTokens ?? 0)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case subtype
        case sessionID = "session_id"
        case createdAt = "created_at"
        case model
        case costUSD = "cost_usd"
        case durationMs = "duration_ms"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case cacheWriteTokens = "cache_write_tokens"
        case message
        case cwd
        case toolName = "tool_name"
    }
}
