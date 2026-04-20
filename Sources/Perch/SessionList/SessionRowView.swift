import SwiftUI

struct SessionRowView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: SessionSnapshot
    @State private var jumpWarning: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                let service = environment.terminalJumpService
                Task {
                    let outcome = await service.jump(to: session)
                    await MainActor.run { handle(outcome: outcome) }
                }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.title)
                            .font(.caption.weight(.semibold))
                        if let subtitle = Self.subtitle(for: session) {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    Spacer()
                    LifecycleChip(state: session.lifecycle)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.title)

            if let jumpWarning {
                Text(jumpWarning)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .transition(.opacity)
                    .accessibilityHint(Text(jumpWarning))
            }
        }
    }

    private static func subtitle(for session: SessionSnapshot) -> String? {
        if let pending = session.pendingPermissions.first { return pending.summary }
        let turn = session.liveTurn
        if let tool = turn.activeToolName {
            if let preview = turn.activeToolPreview, !preview.isEmpty {
                return "\(tool): \(preview)"
            }
            return tool
        }
        if let prompt = turn.lastUserPrompt, !prompt.isEmpty {
            return firstLine(of: prompt)
        }
        return nil
    }

    private static func firstLine(of text: String) -> String {
        let limited = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        if limited.count > 80 {
            return String(limited.prefix(79)) + "…"
        }
        return limited
    }

    private func handle(outcome: JumpOutcome) {
        guard case .notLocated = outcome else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            jumpWarning = "Couldn't find terminal for this session."
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeInOut(duration: 0.2)) { jumpWarning = nil }
        }
    }
}

private struct LifecycleChip: View {
    let state: LifecycleState

    var body: some View {
        HStack(spacing: 4) {
            Text(glyph)
            Text(PerchStrings.lifecycleStateValue(state))
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.18), in: Capsule())
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(PerchStrings.lifecycleStateValue(state))
    }

    private var glyph: String {
        switch state {
        case .idle: return "⏸"
        case .processing: return "⏳"
        case .finished: return "✓"
        case .permission: return "🔔"
        }
    }

    private var tint: Color {
        switch state {
        case .idle: return .secondary
        case .processing: return .blue
        case .finished: return .green
        case .permission: return .orange
        }
    }
}
