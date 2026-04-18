import SwiftUI

struct NotchPanelHost: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NotchRootView(
            session: environment.sessionStore.activeSession,
            familiar: environment.sessionStore.currentFamiliar,
            theme: environment.sessionStore.currentTheme
        )
    }
}
