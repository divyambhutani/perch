import Foundation

enum FamiliarState: String, CaseIterable, Codable, Sendable {
    case idle
    case watching
    case alert
    case working
}
