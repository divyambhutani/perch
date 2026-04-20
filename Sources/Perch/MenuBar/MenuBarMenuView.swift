import AppKit
import SwiftUI

struct MenuBarMenuView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var env = environment
        let tone = environment.sessionStore.currentFamiliar.tone

        return VStack(alignment: .leading, spacing: 12) {
            Text(environment.sessionStore.currentFamiliar.displayName)
                .font(.headline)

            Text(PerchStrings.overlaySubtitle(tone: tone))
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            SessionListView()
            PermissionPromptView()

            Divider()

            Toggle(PerchStrings.notchInsideToggle(tone: tone), isOn: $env.notchMascotInsideNotch)
                .toggleStyle(.switch)
                .controlSize(.small)

            Button(PerchStrings.quitPerch(tone: tone)) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420, alignment: .leading)
    }
}
