import Perch
import SwiftUI

@main
struct PerchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarScene(environment: appDelegate.environment)

        Settings {
            SettingsView()
                .environment(appDelegate.environment)
        }
    }
}
