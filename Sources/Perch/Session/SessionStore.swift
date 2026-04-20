import AppKit
import Foundation
import Observation

@MainActor
@Observable
public final class SessionStore {
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

    var activeSessionID: String { activeSession.sessionIdentifier }
    var pendingPermission: PermissionRequest? { activeSession.pendingPermissions.first }
    var countdown: SessionCountdown { activeSession.countdown }
    var contextWindow: ContextWindowStatus { activeSession.contextWindowStatus }
    var sessionState: SessionState { activeSession.derivedState }
    var totalPendingCount: Int { sessions.reduce(0) { $0 + $1.pendingPermissions.count } }

    var sortedByAttention: [SessionSnapshot] {
        sessions.sorted { lhs, rhs in
            if lhs.derivedState.sortPriority != rhs.derivedState.sortPriority {
                return lhs.derivedState.sortPriority > rhs.derivedState.sortPriority
            }
            return lhs.updatedAt > rhs.updatedAt
        }
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
        let sessionID = event.sessionID ?? eventSessionID(event)
        var snapshot = snapshotForMutation(matchingSessionID: sessionID)
        snapshot.updatedAt = event.receivedAt
        snapshot.isPlaceholder = false
        if let cwd = event.cwd, !cwd.isEmpty {
            snapshot.cwd = cwd
            let basename = URL(fileURLWithPath: cwd).lastPathComponent
            if !basename.isEmpty { snapshot.title = basename }
        }
        if let path = event.transcriptPath, !path.isEmpty {
            snapshot.transcriptPath = path
        }
        if let sessionID, !sessionID.isEmpty {
            snapshot.sessionIdentifier = sessionID
        }
        if let pid = event.terminalPID, pid > 0 {
            snapshot.terminalPID = pid
        }
        if let bundleID = event.terminalBundleID, !bundleID.isEmpty {
            snapshot.terminalBundleID = bundleID
        }

        switch event.kind {
        case .sessionStarted(let sessionID, let transcriptPath, let workingDirectory):
            snapshot.sessionIdentifier = sessionID
            snapshot.transcriptPath = transcriptPath
            snapshot.cwd = workingDirectory
            snapshot.title = makeSessionTitle(workingDirectory: workingDirectory, transcriptPath: transcriptPath)
            snapshot.countdown = .fiveHours(from: event.receivedAt)
            snapshot.familiarState = .watching
            snapshot.statusMessage = "Session started."
        case .sessionEnded(let reason):
            snapshot.familiarState = .idle
            snapshot.statusMessage = reason ?? "Session ended."
        case .notification(let message):
            snapshot.familiarState = .watching
            snapshot.statusMessage = message
            NotificationSound.play()
        case .toolStarted(let name, let commandPreview):
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .working
            if let preview = commandPreview, !preview.isEmpty {
                snapshot.statusMessage = "Running \(name): \(preview)."
            } else {
                snapshot.statusMessage = "Running \(name)."
            }
        case .toolFinished:
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .working
        case .permissionRequired(let summary, let diffPreview):
            let alreadyPending = snapshot.pendingPermissions.contains {
                $0.summary == summary && $0.diffPreview == diffPreview
            }
            if !alreadyPending {
                snapshot.pendingPermissions.append(
                    PermissionRequest(summary: summary, diffPreview: diffPreview)
                )
                NotificationSound.play()
            }
            snapshot.familiarState = .alert
            snapshot.statusMessage = summary
        case .workStarted:
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .working
        case .workFinished:
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .idle
        case .sessionWatching:
            snapshot.familiarState = .watching
        case .contextWindow(let percentage):
            snapshot.contextWindowStatus = ContextWindowStatus(usedPercentage: percentage)
            snapshot.statusMessage = "Context window \(Int(percentage * 100))%."
        case .promptSubmitted:
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .working
            snapshot.statusMessage = "Processing prompt."
        case .stopped:
            snapshot.pendingPermissions.removeAll()
            snapshot.familiarState = .finished
            snapshot.statusMessage = "Finished."
            scheduleFinishedDecay(sessionID: snapshot.sessionIdentifier, after: event.receivedAt)
        case .subagentStopped:
            snapshot.statusMessage = "Subagent finished."
        case .preCompact:
            snapshot.statusMessage = "Compacting context."
        }

        upsert(snapshot)
    }

    func apply(turn: LiveTurn, sessionID: String) {
        guard !sessionID.isEmpty,
              let index = sessions.firstIndex(where: { $0.sessionIdentifier == sessionID }) else { return }
        var snapshot = sessions[index]
        snapshot.liveTurn = turn
        sessions[index] = snapshot
    }

    func apply(metrics: SessionMetrics) {
        var snapshot = snapshotForMutation(matchingSessionID: metrics.sessionID)
        if snapshot.sessionIdentifier != metrics.sessionID {
            snapshot.sessionIdentifier = metrics.sessionID
        }
        snapshot.isPlaceholder = false
        if let cwd = metrics.cwd, !cwd.isEmpty {
            snapshot.cwd = cwd
            let basename = URL(fileURLWithPath: cwd).lastPathComponent
            if !basename.isEmpty,
               snapshot.title == "Primary Session" || snapshot.title.isEmpty || Self.looksLikeProjectSlug(snapshot.title) {
                snapshot.title = basename
            }
        }
        snapshot.contextWindowStatus = ContextWindowStatus(usedPercentage: metrics.contextPercentage)
        if let last = metrics.lastActivity { snapshot.updatedAt = last }
        if let activity = metrics.lastActivity,
           snapshot.familiarState != .alert,
           snapshot.familiarState != .finished {
            let age = Date().timeIntervalSince(activity)
            if age < 15 {
                snapshot.familiarState = .working
            } else if snapshot.familiarState == .working, age > 60 {
                snapshot.familiarState = .watching
            }
        }
        upsert(snapshot)
    }

    func apply(discoveredSessions: [DiscoveredSession]) {
        var next = sessions.filter { !$0.isPlaceholder }

        let collapsed = Self.collapseByProjectAndTerminal(discoveredSessions)

        let discoveredSessionIDs = Set(collapsed.map(\.sessionID))
        let discoveredTranscriptPaths = Set(collapsed.map { $0.jsonlURL.path })
        let fm = FileManager.default
        next.removeAll { snapshot in
            if snapshot.lifecycle == .permission { return false }
            guard let transcriptPath = snapshot.transcriptPath else { return false }
            if discoveredSessionIDs.contains(snapshot.sessionIdentifier) { return false }
            if discoveredTranscriptPaths.contains(transcriptPath) { return false }
            return !fm.fileExists(atPath: transcriptPath)
        }

        for discovered in collapsed {
            let matchIndex = next.firstIndex(where: { snapshot in
                if snapshot.sessionIdentifier == discovered.sessionID { return true }
                if let path = snapshot.transcriptPath, path == discovered.jsonlURL.path { return true }
                return false
            })

            let fallbackTitle = Self.titleForDiscovered(discovered)

            if let index = matchIndex {
                var existing = next[index]
                existing.sessionIdentifier = discovered.sessionID
                if existing.updatedAt < discovered.lastActivity {
                    existing.updatedAt = discovered.lastActivity
                }
                if let cwd = discovered.cwd, !cwd.isEmpty {
                    existing.cwd = cwd
                    existing.title = URL(fileURLWithPath: cwd).lastPathComponent
                } else if existing.title == "Primary Session" || existing.title.isEmpty || Self.looksLikeProjectSlug(existing.title) {
                    existing.title = fallbackTitle
                }
                existing.transcriptPath = discovered.jsonlURL.path
                if let pid = discovered.terminalPID { existing.terminalPID = pid }
                if let bundleID = discovered.terminalBundleID { existing.terminalBundleID = bundleID }
                next[index] = existing
            } else {
                next.append(
                    SessionSnapshot(
                        sessionIdentifier: discovered.sessionID,
                        title: fallbackTitle,
                        transcriptPath: discovered.jsonlURL.path,
                        cwd: discovered.cwd,
                        terminalPID: discovered.terminalPID,
                        terminalBundleID: discovered.terminalBundleID,
                        updatedAt: discovered.lastActivity
                    )
                )
            }
        }

        next.sort { $0.updatedAt > $1.updatedAt }
        sessions = next.isEmpty ? [.placeholder()] : next
    }

    func approvePermission(id: PermissionRequest.ID) { removePermission(id: id) }
    func denyPermission(id: PermissionRequest.ID) { removePermission(id: id) }

    private func removePermission(id: PermissionRequest.ID) {
        guard let index = sessions.firstIndex(where: { snapshot in
            snapshot.pendingPermissions.contains(where: { $0.id == id })
        }) else { return }
        var snapshot = sessions[index]
        snapshot.pendingPermissions.removeAll { $0.id == id }
        snapshot.familiarState = snapshot.pendingPermissions.isEmpty ? .idle : .alert
        upsert(snapshot)
    }

    func installTheme(_ theme: PerchTheme) {
        currentTheme = theme
    }

    private func eventSessionID(_ event: HookEvent) -> String? {
        switch event.kind {
        case .sessionStarted(let sessionID, _, _): return sessionID
        case .promptSubmitted(let sessionID),
             .stopped(let sessionID),
             .subagentStopped(let sessionID),
             .preCompact(let sessionID):
            return sessionID
        default: return nil
        }
    }

    private func scheduleFinishedDecay(sessionID: String, after timestamp: Date) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self else { return }
            guard let index = sessions.firstIndex(where: { $0.sessionIdentifier == sessionID }) else { return }
            var snapshot = sessions[index]
            guard snapshot.familiarState == .finished else { return }
            guard snapshot.updatedAt <= timestamp.addingTimeInterval(0.5) else { return }
            snapshot.familiarState = .idle
            snapshot.statusMessage = "Idle."
            upsert(snapshot)
        }
    }

    private func snapshotForMutation(matchingSessionID sessionID: String?) -> SessionSnapshot {
        if let sessionID, let match = sessions.first(where: { $0.sessionIdentifier == sessionID }) {
            return match
        }
        if let placeholder = sessions.first(where: { $0.isPlaceholder }) {
            return placeholder
        }
        if let sessionID, !sessionID.isEmpty {
            return SessionSnapshot(sessionIdentifier: sessionID, title: "")
        }
        return sessions.first ?? .placeholder()
    }

    private func upsert(_ snapshot: SessionSnapshot) {
        var next = sessions
        if let index = next.firstIndex(where: { $0.id == snapshot.id }) {
            next[index] = snapshot
        } else if let placeholderIndex = next.firstIndex(where: { $0.isPlaceholder }),
                  !snapshot.isPlaceholder {
            next[placeholderIndex] = snapshot
        } else {
            next.append(snapshot)
        }
        next.sort { $0.updatedAt > $1.updatedAt }
        sessions = next
    }

    static func collapseByProjectAndTerminal(_ discovered: [DiscoveredSession]) -> [DiscoveredSession] {
        var byKey: [String: DiscoveredSession] = [:]
        for item in discovered {
            let terminalPart: String
            if let pid = item.terminalPID {
                terminalPart = "pid:\(pid)"
            } else {
                terminalPart = "noterm"
            }
            let key = "\(item.projectDirectory)|\(terminalPart)"
            if let existing = byKey[key], existing.lastActivity >= item.lastActivity {
                continue
            }
            byKey[key] = item
        }
        return byKey.values.sorted { $0.lastActivity > $1.lastActivity }
    }

    static func titleForDiscovered(_ session: DiscoveredSession) -> String {
        if let cwd = session.cwd, !cwd.isEmpty {
            let basename = URL(fileURLWithPath: cwd).lastPathComponent
            if !basename.isEmpty { return basename }
        }
        return decodeProjectSlug(session.projectDirectory)
    }

    static func decodeProjectSlug(_ slug: String) -> String {
        let trimmed = slug.hasPrefix("-") ? String(slug.dropFirst()) : slug
        let segments = trimmed.split(separator: "-", omittingEmptySubsequences: true).map(String.init)
        guard !segments.isEmpty else { return slug }
        let candidate = "/" + segments.joined(separator: "/")
        if FileManager.default.fileExists(atPath: candidate) {
            return URL(fileURLWithPath: candidate).lastPathComponent
        }
        // Walk backward: try joining trailing segments with "-" until a path resolves.
        let maxTail = min(segments.count - 1, 4)
        if maxTail >= 2 {
            for tailCount in 2...maxTail {
                let headSegments = Array(segments.prefix(segments.count - tailCount))
                let tail = segments.suffix(tailCount).joined(separator: "-")
                let probe = "/" + (headSegments + [tail]).joined(separator: "/")
                if FileManager.default.fileExists(atPath: probe) {
                    return URL(fileURLWithPath: probe).lastPathComponent
                }
            }
        }
        return segments.last ?? slug
    }

    static func looksLikeProjectSlug(_ title: String) -> Bool {
        title.hasPrefix("-") && title.contains("Users") && title.contains("-")
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
