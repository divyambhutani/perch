import AppKit
import Foundation

enum JumpOutcome: Sendable, Equatable {
    case activated(TerminalBundle?)
    case appleScriptDispatched(TerminalBundle)
    case fallbackOpenedWorkingDirectory(String?)
    case notLocated
}

protocol AppleScriptRunning: Sendable {
    func run(_ script: String) throws
}

struct SystemAppleScriptRunner: AppleScriptRunning {
    func run(_ script: String) throws {
        var errorDict: NSDictionary?
        let scriptObject = NSAppleScript(source: script)
        _ = scriptObject?.executeAndReturnError(&errorDict)
        if let errorDict {
            throw NSError(domain: "Perch.AppleScript", code: 1, userInfo: errorDict as? [String: Any])
        }
    }
}

protocol AppActivating: Sendable {
    func activate(pid: pid_t)
    func openApplication(at bundleID: String, cwd: String?)
}

struct SystemAppActivator: AppActivating {
    func activate(pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate(options: [.activateAllWindows])
        }
    }

    func openApplication(at bundleID: String, cwd: String?) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        if let cwd, !cwd.isEmpty {
            config.arguments = [cwd]
        }
        NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
    }
}

protocol LiveClaudeEnumerating: Sendable {
    func snapshot() -> [LiveClaudeProcess]
}

struct SystemLiveClaudeEnumerator: LiveClaudeEnumerating {
    func snapshot() -> [LiveClaudeProcess] { LiveClaudeProcessSnapshotter.snapshot() }
}

public actor TerminalJumpService {
    private let locator: any ProcessLocating
    private let script: any AppleScriptRunning
    private let activator: any AppActivating
    private let live: any LiveClaudeEnumerating

    init(
        locator: any ProcessLocating = ProcessLocator(),
        script: any AppleScriptRunning = SystemAppleScriptRunner(),
        activator: any AppActivating = SystemAppActivator(),
        live: any LiveClaudeEnumerating = SystemLiveClaudeEnumerator()
    ) {
        self.locator = locator
        self.script = script
        self.activator = activator
        self.live = live
    }

    func jump(to snapshot: SessionSnapshot) -> JumpOutcome {
        let snapshot = enrichWithLiveScan(snapshot)
        guard let resolved = locator.resolve(for: snapshot) else {
            return fallback(for: snapshot)
        }

        switch resolved.bundle {
        case .appleTerminal:
            let source = Self.appleTerminalScript(pid: resolved.pid)
            do {
                try script.run(source)
                return .appleScriptDispatched(.appleTerminal)
            } catch {
                activator.activate(pid: resolved.pid)
                return .activated(resolved.bundle)
            }
        case .iterm2:
            let tty = Self.ttyForPID(resolved.pid)
            let source = Self.iterm2Script(tty: tty)
            do {
                try script.run(source)
                return .appleScriptDispatched(.iterm2)
            } catch {
                activator.activate(pid: resolved.pid)
                return .activated(resolved.bundle)
            }
        case .some:
            activator.activate(pid: resolved.pid)
            return .activated(resolved.bundle)
        case nil:
            activator.activate(pid: resolved.pid)
            return .activated(nil)
        }
    }

    private func enrichWithLiveScan(_ snapshot: SessionSnapshot) -> SessionSnapshot {
        if snapshot.terminalPID != nil && snapshot.terminalBundleID != nil { return snapshot }
        let processes = live.snapshot()
        guard !processes.isEmpty else { return snapshot }

        var match: LiveClaudeProcess?
        if let cwd = snapshot.cwd, !cwd.isEmpty {
            match = processes.first(where: { $0.cwd == cwd })
        }
        if match == nil, processes.count == 1 {
            match = processes.first
        }
        guard let match else { return snapshot }

        var updated = snapshot
        if updated.terminalPID == nil, let pid = match.terminalPID { updated.terminalPID = pid }
        if updated.terminalBundleID == nil, let bundleID = match.terminalBundleID { updated.terminalBundleID = bundleID }
        if updated.cwd == nil || updated.cwd?.isEmpty == true { updated.cwd = match.cwd }
        return updated
    }

    private func fallback(for snapshot: SessionSnapshot) -> JumpOutcome {
        if let bundleID = snapshot.terminalBundleID {
            activator.openApplication(at: bundleID, cwd: snapshot.cwd)
            return .fallbackOpenedWorkingDirectory(snapshot.cwd)
        }
        if let cwd = snapshot.cwd, !cwd.isEmpty {
            activator.openApplication(at: TerminalBundle.appleTerminal.rawValue, cwd: cwd)
            return .fallbackOpenedWorkingDirectory(cwd)
        }
        return .notLocated
    }

    static func appleTerminalScript(pid: pid_t) -> String {
        """
        tell application "Terminal"
            activate
            set target to missing value
            repeat with w in windows
                repeat with t in tabs of w
                    if (unix id of (processes of t)) contains \(pid) then
                        set target to w
                        exit repeat
                    end if
                end repeat
            end repeat
            if target is not missing value then set frontmost of target to true
        end tell
        """
    }

    static func iterm2Script(tty: String?) -> String {
        guard let tty, !tty.isEmpty else {
            return """
            tell application "iTerm"
                activate
            end tell
            """
        }
        return """
        tell application "iTerm"
            activate
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if (tty of s) contains "\(tty)" then
                            select s
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """
    }

    static func ttyForPID(_ pid: pid_t) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "tty=", "-p", String(pid)]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let raw = String(data: data, encoding: .utf8) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "??" else { return nil }
        return trimmed.hasPrefix("/dev/") ? trimmed : "/dev/\(trimmed)"
    }
}
