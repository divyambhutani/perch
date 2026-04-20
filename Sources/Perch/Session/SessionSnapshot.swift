import Foundation

struct SessionSnapshot: Identifiable, Sendable, Equatable {
    let id: UUID
    var sessionIdentifier: String
    var title: String
    var transcriptPath: String?
    var cwd: String?
    var terminalPID: Int32?
    var terminalBundleID: String?
    var statusMessage: String?
    var familiarState: FamiliarState
    var pendingPermissions: [PermissionRequest]
    var contextWindowStatus: ContextWindowStatus
    var countdown: SessionCountdown
    var liveTurn: LiveTurn
    var updatedAt: Date
    var isPlaceholder: Bool

    init(
        id: UUID = UUID(),
        sessionIdentifier: String,
        title: String,
        transcriptPath: String? = nil,
        cwd: String? = nil,
        terminalPID: Int32? = nil,
        terminalBundleID: String? = nil,
        statusMessage: String? = nil,
        familiarState: FamiliarState = .idle,
        pendingPermissions: [PermissionRequest] = [],
        contextWindowStatus: ContextWindowStatus = .empty,
        countdown: SessionCountdown = .fiveHours(),
        liveTurn: LiveTurn = .empty,
        updatedAt: Date = .now,
        isPlaceholder: Bool = false
    ) {
        self.id = id
        self.sessionIdentifier = sessionIdentifier
        self.title = title
        self.transcriptPath = transcriptPath
        self.cwd = cwd
        self.terminalPID = terminalPID
        self.terminalBundleID = terminalBundleID
        self.statusMessage = statusMessage
        self.familiarState = familiarState
        self.pendingPermissions = pendingPermissions
        self.contextWindowStatus = contextWindowStatus
        self.countdown = countdown
        self.liveTurn = liveTurn
        self.updatedAt = updatedAt
        self.isPlaceholder = isPlaceholder
    }

    static func placeholder() -> SessionSnapshot {
        SessionSnapshot(
            id: UUID(),
            sessionIdentifier: UUID().uuidString,
            title: "Primary Session",
            isPlaceholder: true
        )
    }
}

extension SessionSnapshot {
    var derivedState: SessionState {
        if !pendingPermissions.isEmpty { return .needsAttention }
        switch familiarState {
        case .alert: return .needsAttention
        case .working, .watching: return .active
        case .finished, .idle: return .idle
        }
    }

    var lifecycle: LifecycleState {
        if !pendingPermissions.isEmpty { return .permission }
        switch familiarState {
        case .alert: return .permission
        case .working: return .processing
        case .finished: return .finished
        case .watching, .idle: return .idle
        }
    }
}
