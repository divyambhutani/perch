import Foundation

enum SessionState: Sendable, Equatable {
    case idle
    case active
    case needsAttention
}
