import Foundation

public enum HookInstallationStatus: Sendable, Equatable {
    case notInstalled
    case installed(URL)
}
