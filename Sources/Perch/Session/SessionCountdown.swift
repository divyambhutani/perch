import Foundation

struct SessionCountdown: Sendable, Equatable {
    var startedAt: Date
    var duration: TimeInterval

    var remaining: TimeInterval {
        max(0, duration - Date().timeIntervalSince(startedAt))
    }

    static func fiveHours(from date: Date = .now) -> SessionCountdown {
        SessionCountdown(startedAt: date, duration: 5 * 60 * 60)
    }
}
