import SwiftUI

public struct SessionsPanelHost: View {
    @Environment(AppEnvironment.self) private var environment

    public init() {}

    public var body: some View {
        let sessions = environment.sessionStore.sortedByAttention
        VStack(spacing: 0) {
            if sessions.isEmpty {
                emptyState
            } else {
                ForEach(sessions) { snapshot in
                    SessionRowItem(
                        snapshot: snapshot,
                        onTap: { handleTap(snapshot) }
                    )
                    if snapshot.id != sessions.last?.id {
                        Divider().opacity(0.15)
                    }
                }
            }
        }
        .frame(width: 320)
        .background(PopoverChrome())
    }

    @ViewBuilder
    private var emptyState: some View {
        Text(environment.sessionStore.currentFamiliar.tone.noPendingPermissions)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(16)
    }

    private func handleTap(_ snapshot: SessionSnapshot) {
        environment.jumpToTerminal(for: snapshot)
        environment.setSessionsPanelVisible(false)
    }
}

private struct SessionRowItem: View {
    let snapshot: SessionSnapshot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                StateDot(state: snapshot.derivedState)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(statusLine)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle(emphasized: snapshot.derivedState == .needsAttention))
    }

    private var statusLine: String {
        if let pending = snapshot.pendingPermissions.first {
            return pending.summary
        }
        return snapshot.statusMessage ?? stateLabel
    }

    private var stateLabel: String {
        switch snapshot.derivedState {
        case .needsAttention: return "Needs attention"
        case .active: return "Working"
        case .idle: return "Idle"
        }
    }
}

private struct StateDot: View {
    let state: SessionState

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var color: Color {
        switch state {
        case .needsAttention: return .red
        case .active: return .green
        case .idle: return .secondary
        }
    }
}

private struct RowButtonStyle: ButtonStyle {
    let emphasized: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(background(pressed: configuration.isPressed))
    }

    private func background(pressed: Bool) -> some View {
        Rectangle()
            .fill(tint(pressed: pressed))
    }

    private func tint(pressed: Bool) -> Color {
        if pressed { return Color.white.opacity(0.08) }
        if emphasized { return Color.red.opacity(0.08) }
        return .clear
    }
}

private struct PopoverChrome: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
