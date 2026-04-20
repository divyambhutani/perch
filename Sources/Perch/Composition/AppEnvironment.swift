import Foundation
import Observation

@MainActor
@Observable
public final class AppEnvironment {
    public let sessionStore: SessionStore
    public let hookServer: HookServer
    public let hookInstaller: HookInstaller
    public let jsonlIndexer: JSONLIndexer
    public let databaseManager: DatabaseManager
    public let familiarRegistry: FamiliarRegistry
    public let launchAtLoginController: LaunchAtLoginController
    public let updaterController: UpdaterController
    public let terminalJumpService: TerminalJumpService
    public let onboardingCoordinator: OnboardingCoordinator
    let transcriptTailer: TranscriptTailer
    let sessionDiscovery: SessionDiscovery
    public private(set) var hookInstallationStatus: HookInstallationStatus
    public private(set) var isHookServerRunning: Bool
    public private(set) var hookServerURL: URL
    public private(set) var lastRuntimeError: String?
    public var launchAtLoginEnabled: Bool
    public var launchAtLoginRequiresApproval: Bool
    public var automaticUpdateChecksEnabled: Bool
    public private(set) var canCheckForUpdates: Bool
    public private(set) var updaterFeedConfigured: Bool
    public private(set) var isSessionDiscoveryRunning: Bool
    public private(set) var isSessionsPanelVisible: Bool
    public var notchMascotInsideNotch: Bool {
        didSet {
            guard oldValue != notchMascotInsideNotch else { return }
            Self.notchPreferences.set(notchMascotInsideNotch, forKey: Self.notchInsideKey)
            notchMascotPlacementHandler?(notchMascotInsideNotch)
        }
    }

    private var presentOnboardingHandler: (@MainActor () -> Void)?
    private var sessionsPanelHandler: (@MainActor (Bool) -> Void)?
    private var notchMascotPlacementHandler: (@MainActor (Bool) -> Void)?

    private static let notchInsideKey = "notch.insideNotch.v1"
    private static let notchPreferences: UserDefaults = UserDefaults(suiteName: "com.perch.app") ?? .standard

    init(
        sessionStore: SessionStore,
        hookServer: HookServer,
        hookInstaller: HookInstaller,
        jsonlIndexer: JSONLIndexer,
        databaseManager: DatabaseManager,
        familiarRegistry: FamiliarRegistry,
        launchAtLoginController: LaunchAtLoginController,
        updaterController: UpdaterController,
        terminalJumpService: TerminalJumpService,
        onboardingCoordinator: OnboardingCoordinator,
        transcriptTailer: TranscriptTailer,
        sessionDiscovery: SessionDiscovery
    ) {
        self.sessionStore = sessionStore
        self.hookServer = hookServer
        self.hookInstaller = hookInstaller
        self.jsonlIndexer = jsonlIndexer
        self.databaseManager = databaseManager
        self.familiarRegistry = familiarRegistry
        self.launchAtLoginController = launchAtLoginController
        self.updaterController = updaterController
        self.terminalJumpService = terminalJumpService
        self.onboardingCoordinator = onboardingCoordinator
        self.transcriptTailer = transcriptTailer
        self.sessionDiscovery = sessionDiscovery
        hookInstallationStatus = hookInstaller.status()
        isHookServerRunning = false
        hookServerURL = HookServerConfiguration.endpointURL
        lastRuntimeError = nil
        launchAtLoginEnabled = launchAtLoginController.isEnabled
        launchAtLoginRequiresApproval = launchAtLoginController.requiresApproval
        automaticUpdateChecksEnabled = updaterController.automaticallyChecksForUpdates
        canCheckForUpdates = updaterController.canCheckForUpdates
        updaterFeedConfigured = updaterController.isConfigured
        isSessionDiscoveryRunning = false
        isSessionsPanelVisible = false
        notchMascotInsideNotch = Self.notchPreferences.bool(forKey: Self.notchInsideKey)
    }

    public static func preview() -> AppEnvironment {
        AppBootstrap.makeEnvironment()
    }

    public func startServices() async {
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

        let sessionStore = self.sessionStore
        await transcriptTailer.setHandler { sessionID, turn in
            await MainActor.run {
                sessionStore.apply(turn: turn, sessionID: sessionID)
            }
        }
    }

    public func installHooks() {
        do {
            hookInstallationStatus = try hookInstaller.install(serverURL: hookServerURL)
        } catch {
            lastRuntimeError = String(describing: error)
        }
    }

    public func uninstallHooks() {
        do {
            try hookInstaller.uninstall()
            hookInstallationStatus = hookInstaller.status()
        } catch {
            lastRuntimeError = String(describing: error)
        }
    }

    public func refreshRuntimeState() {
        hookInstallationStatus = hookInstaller.status()
        launchAtLoginEnabled = launchAtLoginController.isEnabled
        launchAtLoginRequiresApproval = launchAtLoginController.requiresApproval
        automaticUpdateChecksEnabled = updaterController.automaticallyChecksForUpdates
        canCheckForUpdates = updaterController.canCheckForUpdates
        updaterFeedConfigured = updaterController.isConfigured
    }

    public func applyLaunchAtLoginChange() {
        do {
            try launchAtLoginController.setEnabled(launchAtLoginEnabled)
            refreshRuntimeState()
        } catch {
            lastRuntimeError = String(describing: error)
            refreshRuntimeState()
        }
    }

    public func openLoginItemsSettings() {
        launchAtLoginController.openSystemSettings()
    }

    public func applyAutomaticUpdatePreference() {
        updaterController.automaticallyChecksForUpdates = automaticUpdateChecksEnabled
        refreshRuntimeState()
    }

    public func checkForUpdates() {
        updaterController.checkForUpdates()
        refreshRuntimeState()
    }

    public func startSessionDiscovery() {
        guard !isSessionDiscoveryRunning else { return }
        isSessionDiscoveryRunning = true
        let sessionStore = self.sessionStore
        let tailer = self.transcriptTailer
        Task { [sessionDiscovery] in
            await sessionDiscovery.start(
                onDiscovery: { discovered in
                    await MainActor.run {
                        sessionStore.apply(discoveredSessions: discovered)
                    }
                    let transcripts = Dictionary(
                        discovered.map { ($0.sessionID, $0.jsonlURL.path) },
                        uniquingKeysWith: { first, _ in first }
                    )
                    await tailer.reconcile(activeTranscripts: transcripts)
                },
                onMetrics: { metrics in
                    await MainActor.run {
                        sessionStore.apply(metrics: metrics)
                    }
                }
            )
        }
    }

    public func setPresentOnboardingHandler(_ handler: @escaping @MainActor () -> Void) {
        presentOnboardingHandler = handler
    }

    public func requestOnboardingRerun() {
        onboardingCoordinator.resetForReRun()
        presentOnboardingHandler?()
    }

    public func setSessionsPanelHandler(_ handler: @escaping @MainActor (Bool) -> Void) {
        sessionsPanelHandler = handler
    }

    public func setNotchMascotPlacementHandler(_ handler: @escaping @MainActor (Bool) -> Void) {
        notchMascotPlacementHandler = handler
        handler(notchMascotInsideNotch)
    }

    public func toggleSessionsPanel() {
        setSessionsPanelVisible(!isSessionsPanelVisible)
    }

    public func setSessionsPanelVisible(_ visible: Bool) {
        guard isSessionsPanelVisible != visible else { return }
        isSessionsPanelVisible = visible
        sessionsPanelHandler?(visible)
    }

    func jumpToTerminal(for snapshot: SessionSnapshot) {
        let service = terminalJumpService
        Task { await service.jump(to: snapshot) }
    }

    public func stopSessionDiscovery() {
        guard isSessionDiscoveryRunning else { return }
        isSessionDiscoveryRunning = false
        Task { [sessionDiscovery] in
            await sessionDiscovery.stop()
        }
    }
}
