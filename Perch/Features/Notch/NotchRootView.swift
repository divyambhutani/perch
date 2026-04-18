import SwiftUI

struct NotchRootView: View {
    let session: SessionSnapshot
    let familiar: any Familiar
    let theme: PerchTheme

    var body: some View {
        HStack(spacing: 16) {
            FamiliarSpriteView(familiar: familiar, theme: theme, state: session.familiarState)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                Text(familiar.displayName)
                    .font(.headline)
                Text(PerchStrings.overlaySubtitle(tone: familiar.tone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.title)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(16)
        .background(PanelChrome())
    }
}
