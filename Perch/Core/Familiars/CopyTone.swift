import Foundation

struct CopyTone: Sendable, Equatable {
    let permissionRequired: String
    let noPendingPermissions: String
    let sessionListTitle: String
    let settingsTitle: String
    let launchAtLogin: String
    let installHooks: String
    let overlaySubtitle: String
}
