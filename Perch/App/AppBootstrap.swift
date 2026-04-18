import Foundation

@MainActor
enum AppBootstrap {
    static func makeEnvironment() -> AppEnvironment {
        let registry = FamiliarRegistry.defaultRegistry()
        let installer = HookInstaller()
        let jsonlIndexer = JSONLIndexer()
        let database = DatabaseManager()
        let hookServer = HookServer()
        let launchAtLoginController = LaunchAtLoginController()
        let updaterController = UpdaterController()
        let theme = ThemePresets.defaultTheme
        let currentFamiliar = registry.familiar(for: .seneca)
        let sessionStore = SessionStore(currentFamiliar: currentFamiliar, currentTheme: theme)

        return AppEnvironment(
            sessionStore: sessionStore,
            hookServer: hookServer,
            hookInstaller: installer,
            jsonlIndexer: jsonlIndexer,
            databaseManager: database,
            familiarRegistry: registry,
            launchAtLoginController: launchAtLoginController,
            updaterController: updaterController
        )
    }
}
