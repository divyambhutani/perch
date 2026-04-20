import SwiftUI

struct MenuBarIconView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Image("SenecaMenuBarTemplate", bundle: PerchBundle.resources)
            .renderingMode(.template)
            .interpolation(.none)
            .resizable()
            .frame(width: 18, height: 18)
            .accessibilityElement()
            .accessibilityLabel(PerchStrings.menuBarLabel())
            .accessibilityValue(
                PerchStrings.familiarStateValue(environment.sessionStore.activeSession.familiarState)
            )
    }
}
