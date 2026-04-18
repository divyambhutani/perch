import SwiftUI

struct ThemePickerView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var sessionStore = environment.sessionStore

        VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.themeTitle())
                .font(.headline)

            Picker(PerchStrings.themeTitle(), selection: $sessionStore.selectedThemeID) {
                ForEach(ThemePresets.all, id: \.id) { theme in
                    Text(PerchStrings.themeDisplayName(for: theme)).tag(theme.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
