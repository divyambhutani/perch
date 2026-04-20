import Foundation

@MainActor
public enum AppBootstrap {
    public static func makeEnvironment() -> AppEnvironment {
        let registry = FamiliarRegistry.defaultRegistry()
        let installer = HookInstaller()
        let jsonlIndexer = JSONLIndexer()
        let database = (try? DatabaseManager(location: .defaultAppSupport))
            ?? (try! DatabaseManager(location: .memory))
        let hookServer = HookServer()
        let launchAtLoginController = LaunchAtLoginController()
        let updaterController = UpdaterController()
        let theme = ThemePresets.defaultTheme
        let currentFamiliar = registry.familiar(for: .seneca)
        let sessionStore = SessionStore(currentFamiliar: currentFamiliar, currentTheme: theme)
        let onboardingCoordinator = OnboardingCoordinator()
        let sessionDiscovery = SessionDiscovery()
        let transcriptTailer = TranscriptTailer()

        return AppEnvironment(
            sessionStore: sessionStore,
            hookServer: hookServer,
            hookInstaller: installer,
            jsonlIndexer: jsonlIndexer,
            databaseManager: database,
            familiarRegistry: registry,
            launchAtLoginController: launchAtLoginController,
            updaterController: updaterController,
            terminalJumpService: TerminalJumpService(),
            onboardingCoordinator: onboardingCoordinator,
            transcriptTailer: transcriptTailer,
            sessionDiscovery: sessionDiscovery
        )
    }
}
