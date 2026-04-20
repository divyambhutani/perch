import Foundation

enum PerchStrings {
    static func permissionRequired(tone: CopyTone) -> String {
        tone.permissionRequired
    }

    static func noPendingPermissions(tone: CopyTone) -> String {
        tone.noPendingPermissions
    }

    static func sessionListTitle(tone: CopyTone) -> String {
        tone.sessionListTitle
    }

    static func settingsTitle(tone: CopyTone) -> String {
        tone.settingsTitle
    }

    static func launchAtLogin(tone: CopyTone) -> String {
        tone.launchAtLogin
    }

    static func installHooks(tone: CopyTone) -> String {
        tone.installHooks
    }

    static func overlaySubtitle(tone: CopyTone) -> String {
        tone.overlaySubtitle
    }

    static func themeTitle() -> String {
        "Theme"
    }

    static func updatesTitle() -> String {
        "Updates"
    }

    static func updatesDescription() -> String {
        "Updater integration will be enabled when the app bundle is finalized."
    }

    static func approveAction() -> String {
        "Approve"
    }

    static func denyAction() -> String {
        "Deny"
    }

    static func noDiffPreview() -> String {
        "No diff preview available."
    }

    static func themeDisplayName(for theme: PerchTheme) -> String {
        theme.displayName
    }

    static func menuBarLabel() -> String {
        "Perch"
    }

    static func familiarStateValue(_ state: FamiliarState) -> String {
        switch state {
        case .idle:
            "Idle"
        case .watching:
            "Watching"
        case .alert:
            "Alert"
        case .working:
            "Working"
        case .finished:
            "Finished"
        }
    }

    static func lifecycleStateValue(_ state: LifecycleState) -> String {
        switch state {
        case .idle:
            "Idle"
        case .processing:
            "Processing"
        case .finished:
            "Finished"
        case .permission:
            "Permission"
        }
    }

    static func installHooksAction() -> String {
        "Install hooks now"
    }

    static func uninstallHooksAction() -> String {
        "Uninstall hooks"
    }

    static func hooksInstalled() -> String {
        "Hooks installed."
    }

    static func hooksNotInstalled() -> String {
        "Hooks not installed."
    }

    static func hookServerListening(at url: URL) -> String {
        "Hook server: \(url.absoluteString)"
    }

    static func runtimeIssueTitle() -> String {
        "Runtime status"
    }

    static func openLoginItemsSettings() -> String {
        "Open Login Items Settings"
    }

    static func launchAtLoginApprovalRequired() -> String {
        "Approval required in System Settings."
    }

    static func checkForUpdatesAction() -> String {
        "Check for Updates"
    }

    static func automaticUpdateChecks() -> String {
        "Automatic update checks"
    }

    static func updaterNotConfigured() -> String {
        "Update feed not configured yet."
    }

    static func onboardingWelcomeTitle(tone: CopyTone) -> String { tone.onboardingWelcomeTitle }
    static func onboardingWelcomeBody(tone: CopyTone) -> String { tone.onboardingWelcomeBody }
    static func onboardingLaunchAtLoginTitle(tone: CopyTone) -> String { tone.onboardingLaunchAtLoginTitle }
    static func onboardingLaunchAtLoginBody(tone: CopyTone) -> String { tone.onboardingLaunchAtLoginBody }
    static func onboardingFileAccessTitle(tone: CopyTone) -> String { tone.onboardingFileAccessTitle }
    static func onboardingFileAccessBody(tone: CopyTone) -> String { tone.onboardingFileAccessBody }
    static func onboardingHooksTitle(tone: CopyTone) -> String { tone.onboardingHooksTitle }
    static func onboardingHooksBody(tone: CopyTone) -> String { tone.onboardingHooksBody }
    static func onboardingCompleteTitle(tone: CopyTone) -> String { tone.onboardingCompleteTitle }
    static func onboardingCompleteBody(tone: CopyTone) -> String { tone.onboardingCompleteBody }
    static func onboardingContinue(tone: CopyTone) -> String { tone.onboardingContinue }
    static func onboardingSkip(tone: CopyTone) -> String { tone.onboardingSkip }
    static func onboardingUnderstood(tone: CopyTone) -> String { tone.onboardingUnderstood }
    static func onboardingInstallHooks(tone: CopyTone) -> String { tone.onboardingInstallHooks }
    static func onboardingOpenPerch(tone: CopyTone) -> String { tone.onboardingOpenPerch }
    static func onboardingResetAction(tone: CopyTone) -> String { tone.onboardingResetAction }
    static func onboardingWindowTitle(tone: CopyTone) -> String { tone.onboardingWindowTitle }
    static func notchInsideToggle(tone: CopyTone) -> String { tone.notchInsideToggle }
    static func quitPerch(tone: CopyTone) -> String { tone.quitPerch }
}
