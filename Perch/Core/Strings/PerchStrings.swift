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

    static func noDiffPreview() -> String {
        "No diff preview available."
    }

    static func themeDisplayName(for theme: PerchTheme) -> String {
        switch theme.id {
        case "default":
            "Default"
        case "midnight":
            "Midnight"
        case "teal":
            "Teal"
        case "plum":
            "Plum"
        case "pewter":
            "Pewter"
        case "highContrast":
            "High Contrast"
        default:
            theme.id
        }
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
        }
    }

    static func installHooksAction() -> String {
        "Install hooks now"
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
}
