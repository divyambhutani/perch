import Foundation

enum InstallerError: Error, Sendable {
    case templateMissing
    case settingsEncodingFailed
}
