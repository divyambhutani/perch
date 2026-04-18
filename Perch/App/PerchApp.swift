import SwiftUI

@main
struct PerchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var environment: AppEnvironment

    init() {
        let environment = AppBootstrap.makeEnvironment()
        _environment = State(initialValue: environment)

        Task { @MainActor in
            await environment.startServices()
        }
    }

    var body: some Scene {
        MenuBarScene(environment: environment)

        Settings {
            SettingsView()
                .environment(environment)
        }
    }
}
