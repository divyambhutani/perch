import Foundation

struct HookInstaller: Sendable {
    private let baseDirectoryURL: URL

    init(baseDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.baseDirectoryURL = baseDirectoryURL
    }

    private var claudeDirectoryURL: URL {
        baseDirectoryURL.appending(path: ".claude")
    }

    private var hooksDirectoryURL: URL {
        claudeDirectoryURL.appending(path: "hooks")
    }

    func installationURL() -> URL {
        hooksDirectoryURL.appending(path: "perch-hook.sh")
    }

    func settingsURL() -> URL {
        claudeDirectoryURL.appending(path: "settings.json")
    }

    func status() -> HookInstallationStatus {
        FileManager.default.fileExists(atPath: installationURL().path) ? .installed(installationURL()) : .notInstalled
    }

    func installScriptContents() throws -> String {
        """
        #!/bin/zsh
        set -euo pipefail

        /usr/bin/curl --silent --show-error --max-time 2 \\
          -X POST \\
          -H "Content-Type: application/json" \\
          --data-binary @- \\
          "\(HookServerConfiguration.endpointURL.absoluteString)" >/dev/null 2>&1 || true

        exit 0
        """
    }

    func install() throws -> HookInstallationStatus {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: hooksDirectoryURL, withIntermediateDirectories: true)

        let scriptURL = installationURL()
        try installScriptContents().write(to: scriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        try upsertClaudeSettings()
        return .installed(scriptURL)
    }

    private func upsertClaudeSettings() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: claudeDirectoryURL, withIntermediateDirectories: true)

        let settingsURL = settingsURL()
        let existingData = fileManager.fileExists(atPath: settingsURL.path) ? try Data(contentsOf: settingsURL) : Data("{}".utf8)
        let rootObject = try JSONSerialization.jsonObject(with: existingData)
        var root = rootObject as? [String: Any] ?? [:]
        var hooks = root["hooks"] as? [String: Any] ?? [:]

        hooks["Notification"] = mergedEventEntries(
            existing: hooks["Notification"],
            matcher: nil
        )
        hooks["SessionStart"] = mergedEventEntries(
            existing: hooks["SessionStart"],
            matcher: nil
        )
        hooks["SessionEnd"] = mergedEventEntries(
            existing: hooks["SessionEnd"],
            matcher: nil
        )
        hooks["PreToolUse"] = mergedEventEntries(
            existing: hooks["PreToolUse"],
            matcher: "*"
        )
        hooks["PostToolUse"] = mergedEventEntries(
            existing: hooks["PostToolUse"],
            matcher: "*"
        )

        root["hooks"] = hooks

        guard JSONSerialization.isValidJSONObject(root) else {
            throw InstallerError.settingsEncodingFailed
        }

        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsURL, options: .atomic)
    }

    private func mergedEventEntries(existing: Any?, matcher: String?) -> [[String: Any]] {
        let commandHook: [String: Any] = [
            "type": "command",
            "command": installationURL().path
        ]

        var entries = existing as? [[String: Any]] ?? []
        if let index = entries.firstIndex(where: { ($0["matcher"] as? String) == matcher }) {
            var entry = entries[index]
            var nestedHooks = entry["hooks"] as? [[String: Any]] ?? []
            if !nestedHooks.contains(where: { ($0["command"] as? String) == installationURL().path }) {
                nestedHooks.append(commandHook)
            }
            entry["hooks"] = nestedHooks
            if let matcher {
                entry["matcher"] = matcher
            }
            entries[index] = entry
        } else {
            var entry: [String: Any] = [
                "hooks": [commandHook]
            ]
            if let matcher {
                entry["matcher"] = matcher
            }
            entries.append(entry)
        }

        return entries
    }
}
