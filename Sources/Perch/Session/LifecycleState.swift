import Foundation

enum LifecycleState: String, Sendable, CaseIterable {
    case idle
    case processing
    case finished
    case permission
}
