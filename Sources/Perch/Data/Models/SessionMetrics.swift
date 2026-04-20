import Foundation

struct SessionMetrics: Codable, Sendable, Equatable {
    var sessionID: String
    var project: String?
    var cwd: String?
    var startedAt: Date?
    var lastActivity: Date?
    var totalTokens: Int
    var totalCostUSD: Double
    var contextPercentage: Double
    var eventCount: Int

    static func empty(sessionID: String) -> SessionMetrics {
        SessionMetrics(
            sessionID: sessionID,
            totalTokens: 0,
            totalCostUSD: 0,
            contextPercentage: 0,
            eventCount: 0
        )
    }

    mutating func fold(_ event: TranscriptEvent) {
        eventCount += 1
        totalTokens += event.totalTokens
        totalCostUSD += event.costUSD ?? 0

        if let cwd = event.cwd, !cwd.isEmpty {
            self.cwd = cwd
        }

        if let ts = event.createdAt {
            if startedAt == nil || ts < (startedAt ?? .distantFuture) {
                startedAt = ts
            }
            if lastActivity == nil || ts > (lastActivity ?? .distantPast) {
                lastActivity = ts
            }
        }
    }
}
