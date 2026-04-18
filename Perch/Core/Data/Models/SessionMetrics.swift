import Foundation

struct SessionMetrics: Codable, Sendable, Equatable {
    var tokenBurnRate: Double
    var contextPercentage: Double
}
