import Foundation

enum HookInstallationStatus: Sendable, Equatable {
    case notInstalled
    case installed(URL)
}
