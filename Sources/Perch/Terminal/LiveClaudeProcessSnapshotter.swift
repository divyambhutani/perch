import AppKit
import Foundation

struct LiveClaudeProcess: Sendable, Equatable {
    let pid: pid_t
    let cwd: String
    let terminalPID: pid_t?
    let terminalBundleID: String?
}

enum LiveClaudeProcessSnapshotter {
    static func snapshot() -> [LiveClaudeProcess] {
        let parents = parentsByPID()
        let terminalByPID = terminalBundleByPID()
        var claudePIDs = enumerateClaudeCLIPIDs()
        if claudePIDs.isEmpty {
            claudePIDs = pgrepClaudeCLIPIDs()
        }
        var results: [LiveClaudeProcess] = []
        for pid in claudePIDs {
            guard let cwd = cwd(forPID: pid) else { continue }
            let (termPID, bundleID) = walkParents(startingAt: pid, parents: parents, terminals: terminalByPID)
            results.append(
                LiveClaudeProcess(
                    pid: pid,
                    cwd: cwd,
                    terminalPID: termPID,
                    terminalBundleID: bundleID
                )
            )
        }
        return results
    }

    private static func pgrepClaudeCLIPIDs() -> [pid_t] {
        guard let output = runShell("/usr/bin/pgrep", args: ["-fl", "claude"]) else { return [] }
        var pids: [pid_t] = []
        for line in output.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let spaceIdx = trimmed.firstIndex(of: " ") else { continue }
            let pidStr = String(trimmed[..<spaceIdx])
            let argStr = String(trimmed[trimmed.index(after: spaceIdx)...])
            guard let pid = pid_t(pidStr) else { continue }
            if isClaudeCLICommand(argStr) {
                pids.append(pid)
            }
        }
        return pids
    }

    static func encodeProjectDirectory(from cwd: String) -> String {
        let normalized = cwd
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        return normalized
    }

    private static func parentsByPID() -> [pid_t: pid_t] {
        guard let output = runShell("/bin/ps", args: ["-axo", "pid=,ppid="]) else { return [:] }
        var map: [pid_t: pid_t] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard parts.count >= 2,
                  let pid = pid_t(parts[0]),
                  let ppid = pid_t(parts[1]) else { continue }
            map[pid] = ppid
        }
        return map
    }

    private static func enumerateClaudeCLIPIDs() -> [pid_t] {
        guard let output = runShell("/bin/ps", args: ["-axo", "pid=,args="]) else { return [] }
        var pids: [pid_t] = []
        for line in output.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let spaceIdx = trimmed.firstIndex(of: " ") else { continue }
            let pidStr = String(trimmed[..<spaceIdx])
            let argStr = String(trimmed[trimmed.index(after: spaceIdx)...])
            guard let pid = pid_t(pidStr) else { continue }
            if isClaudeCLICommand(argStr) {
                pids.append(pid)
            }
        }
        return pids
    }

    private static func isClaudeCLICommand(_ args: String) -> Bool {
        if args.contains("Claude.app/") { return false }
        if args.contains("Claude Island") { return false }
        if args.contains("Claude Helper") { return false }
        if args.contains("claude-island") { return false }

        if args.hasSuffix("/claude") { return true }
        if args.contains("/claude ") { return true }
        if args.contains("@anthropic-ai/claude-code") { return true }
        if args.contains("claude-code/cli") { return true }
        return false
    }

    private static func cwd(forPID pid: pid_t) -> String? {
        guard let output = runShell("/usr/sbin/lsof", args: ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"]) else { return nil }
        for line in output.split(whereSeparator: \.isNewline) where line.hasPrefix("n") {
            return String(line.dropFirst())
        }
        return nil
    }

    private static func terminalBundleByPID() -> [pid_t: String] {
        var map: [pid_t: String] = [:]
        for app in NSWorkspace.shared.runningApplications {
            guard let bundleID = app.bundleIdentifier else { continue }
            if TerminalBundle.from(bundleID: bundleID) != nil {
                map[app.processIdentifier] = bundleID
            }
        }
        return map
    }

    private static func walkParents(
        startingAt pid: pid_t,
        parents: [pid_t: pid_t],
        terminals: [pid_t: String]
    ) -> (pid_t?, String?) {
        var current = parents[pid]
        var depth = 0
        while let p = current, depth < 40, p > 1 {
            if let bundleID = terminals[p] {
                return (p, bundleID)
            }
            current = parents[p]
            depth += 1
        }
        return (nil, nil)
    }

    private static func runShell(_ path: String, args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
