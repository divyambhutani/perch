import SwiftUI

struct NotchRootView: View {
    let session: SessionSnapshot
    let familiar: any Familiar
    let theme: PerchTheme
    let notificationCount: Int
    let onTap: () -> Void
    var compact: Bool = false

    private var spriteSize: CGFloat { compact ? 22 : 52 }
    private var padding: CGFloat { compact ? 2 : 12 }
    private var badgeOffset: CGSize { compact ? .init(width: 2, height: -2) : .init(width: 4, height: -4) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FamiliarSpriteView(familiar: familiar, theme: theme, state: session.familiarState)
                .frame(width: spriteSize, height: spriteSize)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }

            if notificationCount > 0 {
                NotificationBadge(count: notificationCount, compact: compact)
                    .offset(x: badgeOffset.width, y: badgeOffset.height)
                    .allowsHitTesting(false)
            }
        }
        .padding(padding)
    }
}

private struct NotificationBadge: View {
    let count: Int
    var compact: Bool = false

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: compact ? 8 : 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 3 : 5)
            .padding(.vertical, compact ? 1 : 2)
            .background(Capsule().fill(Color.red))
            .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }
}
