import AppKit
import SwiftUI

public struct NotchPanelHost: View {
    @Environment(AppEnvironment.self) private var environment
    var compact: Bool

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        @Bindable var env = environment
        let tone = environment.sessionStore.currentFamiliar.tone

        return NotchRootView(
            session: environment.sessionStore.activeSession,
            familiar: environment.sessionStore.currentFamiliar,
            theme: environment.sessionStore.currentTheme,
            notificationCount: environment.sessionStore.totalPendingCount,
            onTap: { environment.toggleSessionsPanel() },
            compact: compact
        )
        .contextMenu {
            Toggle(PerchStrings.notchInsideToggle(tone: tone), isOn: $env.notchMascotInsideNotch)
            Divider()
            Button(PerchStrings.quitPerch(tone: tone)) { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
