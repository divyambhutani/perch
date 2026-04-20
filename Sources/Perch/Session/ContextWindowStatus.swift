import Foundation

struct ContextWindowStatus: Sendable, Equatable {
    var usedPercentage: Double

    static let empty = ContextWindowStatus(usedPercentage: 0)
}
