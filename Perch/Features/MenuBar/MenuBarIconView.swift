import SwiftUI

struct MenuBarIconView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        FamiliarSpriteView(
            familiar: environment.sessionStore.currentFamiliar,
            theme: environment.sessionStore.currentTheme,
            state: environment.sessionStore.activeSession.familiarState
        )
        .frame(width: 20, height: 20)
        .accessibilityElement()
        .accessibilityLabel(PerchStrings.menuBarLabel())
        .accessibilityValue(
            PerchStrings.familiarStateValue(environment.sessionStore.activeSession.familiarState)
        )
    }
}
