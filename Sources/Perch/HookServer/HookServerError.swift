import Foundation

enum HookServerError: Error, Sendable, Equatable {
    case invalidPayload
    case incompleteRequest
    case unsupportedMethod(String)
    case unsupportedPath(String)
    case noAvailablePort
    case bindFailed(String)
}
