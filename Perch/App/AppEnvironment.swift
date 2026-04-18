import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let sessionStore: SessionStore
    let hookServer: HookServer
    let hookInstaller: HookInstaller
    let jsonlIndexer: JSONLIndexer
    let databaseManager: DatabaseManager
    let familiarRegistry: FamiliarRegistry
    let launchAtLoginController: LaunchAtLoginController
    let updaterController: UpdaterController
    private(set) var hookInstallationStatus: HookInstallationStatus
    private(set) var isHookServerRunning: Bool
    private(set) var hookServerURL: URL
    private(set) var lastRuntimeError: String?
    var launchAtLoginEnabled: Bool
    var launchAtLoginRequiresApproval: Bool
    var automaticUpdateChecksEnabled: Bool
    private(set) var canCheckForUpdates: Bool
    private(set) var updaterFeedConfigured: Bool

    init(
        sessionStore: SessionStore,
        hookServer: HookServer,
        hookInstaller: HookInstaller,
        jsonlIndexer: JSONLIndexer,
        databaseManager: DatabaseManager,
        familiarRegistry: FamiliarRegistry,
        launchAtLoginController: LaunchAtLoginController,
        updaterController: UpdaterController
    ) {
        self.sessionStore = sessionStore
        self.hookServer = hookServer
        self.hookInstaller = hookInstaller
        self.jsonlIndexer = jsonlIndexer
        self.databaseManager = databaseManager
        self.familiarRegistry = familiarRegistry
        self.launchAtLoginController = launchAtLoginController
        self.updaterController = updaterController
        hookInstallationStatus = hookInstaller.status()
        isHookServerRunning = false
        hookServerURL = HookServerConfiguration.endpointURL
        lastRuntimeError = nil
        launchAtLoginEnabled = launchAtLoginController.isEnabled
        launchAtLoginRequiresApproval = launchAtLoginController.requiresApproval
        automaticUpdateChecksEnabled = updaterController.automaticallyChecksForUpdates
        canCheckForUpdates = updaterController.canCheckForUpdates
        updaterFeedConfigured = updaterController.isConfigured
    }

    static func preview() -> AppEnvironment {
        AppBootstrap.makeEnvironment()
    }

    func startServices() async {
        refreshRuntimeState()

        do {
            let port = try await hookServer.start { [weak self] event in
                await MainActor.run {
                    self?.sessionStore.apply(event: event)
                }
            }
            isHookServerRunning = true
            hookServerURL = HookServerConfiguration.url(for: port)
        } catch {
            lastRuntimeError = String(describing: error)
        }
    }

    func installHooks() {
        do {
            hookInstallationStatus = try hookInstaller.install()
        } catch {
            lastRuntimeError = String(describing: error)
        }
    }

    func refreshRuntimeState() {
        hookInstallationStatus = hookInstaller.status()
        launchAtLoginEnabled = launchAtLoginController.isEnabled
        launchAtLoginRequiresApproval = launchAtLoginController.requiresApproval
        automaticUpdateChecksEnabled = updaterController.automaticallyChecksForUpdates
        canCheckForUpdates = updaterController.canCheckForUpdates
        updaterFeedConfigured = updaterController.isConfigured
    }

    func applyLaunchAtLoginChange() {
        do {
            try launchAtLoginController.setEnabled(launchAtLoginEnabled)
            refreshRuntimeState()
        } catch {
            lastRuntimeError = String(describing: error)
            refreshRuntimeState()
        }
    }

    func openLoginItemsSettings() {
        launchAtLoginController.openSystemSettings()
    }

    func applyAutomaticUpdatePreference() {
        updaterController.automaticallyChecksForUpdates = automaticUpdateChecksEnabled
        refreshRuntimeState()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates()
        refreshRuntimeState()
    }
}
