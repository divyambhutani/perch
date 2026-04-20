import Foundation

enum SessionState: Sendable, Equatable {
    case idle
    case active
    case needsAttention

    var sortPriority: Int {
        switch self {
        case .needsAttention: return 2
        case .active: return 1
        case .idle: return 0
        }
    }
}
