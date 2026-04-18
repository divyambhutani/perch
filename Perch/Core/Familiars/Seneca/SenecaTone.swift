import Foundation

enum SenecaTone {
    static let value = CopyTone(
        permissionRequired: "Permission required.",
        noPendingPermissions: "Nothing requires review.",
        sessionListTitle: "Sessions",
        settingsTitle: "Settings",
        launchAtLogin: "Launch at login",
        installHooks: "Install hooks",
        overlaySubtitle: "State changes surface here."
    )
}
