import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [SessionSnapshot]
    private(set) var currentFamiliar: any Familiar
    private(set) var currentTheme: PerchTheme

    init(
        sessions: [SessionSnapshot] = [.placeholder()],
        currentFamiliar: any Familiar,
        currentTheme: PerchTheme
    ) {
        self.sessions = sessions
        self.currentFamiliar = currentFamiliar
        self.currentTheme = currentTheme
    }

    var activeSession: SessionSnapshot {
        sessions.first ?? .placeholder()
    }

    var selectedThemeID: String {
        get { currentTheme.id }
        set {
            guard let theme = ThemePresets.all.first(where: { $0.id == newValue }) else {
                return
            }
            currentTheme = theme
        }
    }

    func apply(event: HookEvent) {
        var session = sessions.first ?? .placeholder()
        session.updatedAt = event.receivedAt

        switch event.kind {
        case .sessionStarted(let sessionID, let transcriptPath, let workingDirectory):
            session.sessionIdentifier = sessionID
            session.transcriptPath = transcriptPath
            session.title = makeSessionTitle(workingDirectory: workingDirectory, transcriptPath: transcriptPath)
            session.countdown = .fiveHours(from: event.receivedAt)
            session.familiarState = .watching
            session.statusMessage = "Session started."
        case .sessionEnded(let reason):
            session.familiarState = .idle
            session.statusMessage = reason ?? "Session ended."
        case .notification(let message):
            session.familiarState = .watching
            session.statusMessage = message
        case .toolStarted(let name):
            session.familiarState = .working
            session.statusMessage = "Running \(name)."
        case .toolFinished(let name):
            session.familiarState = session.pendingPermissions.isEmpty ? .watching : .alert
            session.statusMessage = "Completed \(name)."
        case .permissionRequired(let summary, let diffPreview):
            session.pendingPermissions.append(
                PermissionRequest(summary: summary, diffPreview: diffPreview)
            )
            session.familiarState = .alert
            session.statusMessage = summary
        case .workStarted:
            session.familiarState = .working
        case .workFinished:
            session.familiarState = session.pendingPermissions.isEmpty ? .idle : .alert
        case .sessionWatching:
            session.familiarState = .watching
        case .contextWindow(let percentage):
            session.contextWindowStatus = ContextWindowStatus(usedPercentage: percentage)
            session.statusMessage = "Context window \(Int(percentage * 100))%."
        }

        sessions = [session]
    }

    func approvePermission(id: PermissionRequest.ID) {
        guard var session = sessions.first else {
            return
        }

        session.pendingPermissions.removeAll { $0.id == id }
        session.familiarState = session.pendingPermissions.isEmpty ? .idle : .alert
        sessions = [session]
    }

    func installTheme(_ theme: PerchTheme) {
        currentTheme = theme
    }

    private func makeSessionTitle(workingDirectory: String?, transcriptPath: String?) -> String {
        if let workingDirectory, !workingDirectory.isEmpty {
            let lastPathComponent = URL(fileURLWithPath: workingDirectory).lastPathComponent
            if !lastPathComponent.isEmpty {
                return lastPathComponent
            }
        }

        if let transcriptPath, !transcriptPath.isEmpty {
            return URL(fileURLWithPath: transcriptPath).deletingPathExtension().lastPathComponent
        }

        return "Primary Session"
    }
}
