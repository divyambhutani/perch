import Foundation

public struct HookInstaller: Sendable {
    static let ownershipKey = "_perch"
    static let versionKey = "_perchVersion"
    static let currentVersion = 2
    static let hookEvents = [
        "Notification",
        "SessionStart",
        "SessionEnd",
        "PreToolUse",
        "PostToolUse",
        "UserPromptSubmit",
        "Stop",
        "SubagentStop",
        "PreCompact"
    ]

    private let baseDirectoryURL: URL

    init(baseDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.baseDirectoryURL = baseDirectoryURL
    }

    private var claudeDirectoryURL: URL { baseDirectoryURL.appending(path: ".claude") }
    private var hooksDirectoryURL: URL { claudeDirectoryURL.appending(path: "hooks") }

    func installationURL() -> URL { hooksDirectoryURL.appending(path: "perch-hook-v2.sh") }
    func settingsURL() -> URL { claudeDirectoryURL.appending(path: "settings.json") }

    func status() -> HookInstallationStatus {
        FileManager.default.fileExists(atPath: installationURL().path)
            ? .installed(installationURL())
            : .notInstalled
    }

    func installScriptContents(serverURL: URL) -> String {
        """
        #!/bin/zsh
        set -uo pipefail

        # Walk parent chain to find the terminal emulator hosting this claude session.
        # We inject the matching PID + bundleID as HTTP headers so Perch can jump
        # directly to the right window/tab even when the PPID chain crosses tmux,
        # nested shells, or IDE helper processes.
        terminal_pid=""
        terminal_bundle=""
        pid=$PPID
        for _ in {1..40}; do
          [[ -z "$pid" || "$pid" == "0" || "$pid" == "1" ]] && break
          bid=$(/usr/bin/lsappinfo info -only bundleid "$pid" 2>/dev/null | /usr/bin/awk -F'"' '/kLSBundleIdentifierKey/ {print $4}')
          case "$bid" in
            com.apple.Terminal|com.googlecode.iterm2|com.mitchellh.ghostty|dev.warp.Warp-Stable|io.alacritty|net.kovidgoyal.kitty|com.microsoft.VSCode|com.visualstudio.code.oss|com.todesktop.230313mzl4w4u92|co.zeit.hyper|org.hyper.Hyper|com.raycast.macos|dev.zed.Zed|com.github.wez.wezterm|org.tabby)
              terminal_pid=$pid
              terminal_bundle=$bid
              break
              ;;
          esac
          ppid=$(/bin/ps -o ppid= -p "$pid" 2>/dev/null | /usr/bin/tr -d ' ')
          [[ -z "$ppid" ]] && break
          pid=$ppid
        done

        headers=(-H "Content-Type: application/json")
        if [[ -n "$terminal_pid" ]]; then
          headers+=(-H "X-Perch-Terminal-PID: $terminal_pid")
          headers+=(-H "X-Perch-Terminal-Bundle: $terminal_bundle")
        fi

        /usr/bin/curl --silent --show-error --max-time 2 \\
          -X POST \\
          "${headers[@]}" \\
          --data-binary @- \\
          "\(serverURL.absoluteString)" >/dev/null 2>&1 || true

        exit 0
        """
    }

    @discardableResult
    func install(serverURL: URL = HookServerConfiguration.endpointURL) throws -> HookInstallationStatus {
        let fm = FileManager.default
        try fm.createDirectory(at: hooksDirectoryURL, withIntermediateDirectories: true)

        let scriptURL = installationURL()
        try installScriptContents(serverURL: serverURL).write(to: scriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        try upsertClaudeSettings()
        return .installed(scriptURL)
    }

    func uninstall() throws {
        let fm = FileManager.default
        try? fm.removeItem(at: installationURL())
        try pruneClaudeSettings()
    }

    private func upsertClaudeSettings() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: claudeDirectoryURL, withIntermediateDirectories: true)

        var root = try loadSettings()
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        for event in Self.hookEvents {
            let matcher: String? = (event == "PreToolUse" || event == "PostToolUse") ? "*" : nil
            hooks[event] = mergedEventEntries(existing: hooks[event], matcher: matcher)
        }
        root["hooks"] = hooks
        try writeSettings(root)
    }

    private func pruneClaudeSettings() throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsURL().path) else { return }

        var root = try loadSettings()
        guard var hooks = root["hooks"] as? [String: Any] else { return }

        for event in Self.hookEvents {
            guard var entries = hooks[event] as? [[String: Any]] else { continue }
            entries = entries.compactMap { entry in
                var entry = entry
                var nested = entry["hooks"] as? [[String: Any]] ?? []
                nested.removeAll { ($0[Self.ownershipKey] as? Bool) == true }
                if nested.isEmpty { return nil }
                entry["hooks"] = nested
                return entry
            }
            hooks[event] = entries.isEmpty ? nil : entries
        }
        root["hooks"] = hooks
        try writeSettings(root)
    }

    private func loadSettings() throws -> [String: Any] {
        let fm = FileManager.default
        let data = fm.fileExists(atPath: settingsURL().path)
            ? try Data(contentsOf: settingsURL())
            : Data("{}".utf8)
        let any = try JSONSerialization.jsonObject(with: data)
        return any as? [String: Any] ?? [:]
    }

    private func writeSettings(_ root: [String: Any]) throws {
        guard JSONSerialization.isValidJSONObject(root) else {
            throw InstallerError.settingsEncodingFailed
        }
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsURL(), options: .atomic)
    }

    private func mergedEventEntries(existing: Any?, matcher: String?) -> [[String: Any]] {
        let commandHook: [String: Any] = [
            "type": "command",
            "command": installationURL().path,
            Self.ownershipKey: true,
            Self.versionKey: Self.currentVersion
        ]

        var entries = existing as? [[String: Any]] ?? []
        if let index = entries.firstIndex(where: { ($0["matcher"] as? String) == matcher }) {
            var entry = entries[index]
            var nested = entry["hooks"] as? [[String: Any]] ?? []
            if let existingIndex = nested.firstIndex(where: { ($0[Self.ownershipKey] as? Bool) == true }) {
                nested[existingIndex] = commandHook
            } else {
                nested.append(commandHook)
            }
            entry["hooks"] = nested
            if let matcher {
                entry["matcher"] = matcher
            }
            entries[index] = entry
        } else {
            var entry: [String: Any] = ["hooks": [commandHook]]
            if let matcher {
                entry["matcher"] = matcher
            }
            entries.append(entry)
        }
        return entries
    }
}
