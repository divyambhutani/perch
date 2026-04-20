import Foundation
import GRDB

struct SessionRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    var id: String
    var project: String?
    var cwd: String?
    var startedAt: Date?
    var lastActivity: Date?
    var state: String
    var contextPct: Double
    var tokenTotal: Int

    static let databaseTableName = "sessions"

    init(metrics: SessionMetrics, state: String = "idle") {
        id = metrics.sessionID
        project = metrics.project
        cwd = metrics.cwd
        startedAt = metrics.startedAt
        lastActivity = metrics.lastActivity
        self.state = state
        contextPct = metrics.contextPercentage
        tokenTotal = metrics.totalTokens
    }

    init(
        id: String,
        project: String? = nil,
        cwd: String? = nil,
        startedAt: Date? = nil,
        lastActivity: Date? = nil,
        state: String,
        contextPct: Double,
        tokenTotal: Int
    ) {
        self.id = id
        self.project = project
        self.cwd = cwd
        self.startedAt = startedAt
        self.lastActivity = lastActivity
        self.state = state
        self.contextPct = contextPct
        self.tokenTotal = tokenTotal
    }
}
