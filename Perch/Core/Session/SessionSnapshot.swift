import Foundation

struct SessionSnapshot: Identifiable, Sendable, Equatable {
    let id: UUID
    var sessionIdentifier: String
    var title: String
    var transcriptPath: String?
    var statusMessage: String?
    var familiarState: FamiliarState
    var pendingPermissions: [PermissionRequest]
    var contextWindowStatus: ContextWindowStatus
    var countdown: SessionCountdown
    var updatedAt: Date

    static func placeholder() -> SessionSnapshot {
        SessionSnapshot(
            id: UUID(),
            sessionIdentifier: UUID().uuidString,
            title: "Primary Session",
            transcriptPath: nil,
            statusMessage: nil,
            familiarState: .idle,
            pendingPermissions: [],
            contextWindowStatus: .empty,
            countdown: .fiveHours(),
            updatedAt: .now
        )
    }
}
