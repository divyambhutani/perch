import Foundation

public struct DiscoveredSession: Sendable, Equatable, Hashable {
    public let jsonlURL: URL
    public let sessionID: String
    public let projectDirectory: String
    public let lastActivity: Date
    public let cwd: String?
    public let terminalPID: Int32?
    public let terminalBundleID: String?
    public let isLive: Bool

    public init(
        jsonlURL: URL,
        sessionID: String,
        projectDirectory: String,
        lastActivity: Date,
        cwd: String? = nil,
        terminalPID: Int32? = nil,
        terminalBundleID: String? = nil,
        isLive: Bool = false
    ) {
        self.jsonlURL = jsonlURL
        self.sessionID = sessionID
        self.projectDirectory = projectDirectory
        self.lastActivity = lastActivity
        self.cwd = cwd
        self.terminalPID = terminalPID
        self.terminalBundleID = terminalBundleID
        self.isLive = isLive
    }
}
