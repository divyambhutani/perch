import AppKit
import Foundation

protocol ProcessLocating: Sendable {
    func resolve(for snapshot: SessionSnapshot) -> ResolvedTerminal?
}

struct ResolvedTerminal: Sendable, Equatable {
    let pid: pid_t
    let bundle: TerminalBundle?
    let bundleID: String?
}

struct ProcessLocator: ProcessLocating {
    private let runningApplications: @Sendable () -> [NSRunningApplication]

    init(runningApplications: @escaping @Sendable () -> [NSRunningApplication] = { NSWorkspace.shared.runningApplications }) {
        self.runningApplications = runningApplications
    }

    func resolve(for snapshot: SessionSnapshot) -> ResolvedTerminal? {
        if let pid = snapshot.terminalPID {
            if let bundleID = snapshot.terminalBundleID {
                return ResolvedTerminal(pid: pid, bundle: TerminalBundle.from(bundleID: bundleID), bundleID: bundleID)
            }
            let app = runningApplications().first(where: { $0.processIdentifier == pid })
            let bundleID = app?.bundleIdentifier
            return ResolvedTerminal(pid: pid, bundle: TerminalBundle.from(bundleID: bundleID), bundleID: bundleID)
        }

        if let bundleID = snapshot.terminalBundleID,
           let app = runningApplications().first(where: { $0.bundleIdentifier == bundleID }) {
            return ResolvedTerminal(pid: app.processIdentifier, bundle: TerminalBundle.from(bundleID: bundleID), bundleID: bundleID)
        }

        return nil
    }
}
