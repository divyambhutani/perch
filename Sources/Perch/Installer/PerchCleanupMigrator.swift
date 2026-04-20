import Foundation

public enum PerchCleanupMigrator {
    static let ranKey = "perch.cleanup.v2.ran"
    static let preserveKeys = ["onboarding.v1.completed", "notch.insideNotch.v1"]

    public static func runOnce(
        baseDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        standardDefaults: UserDefaults = .standard
    ) {
        guard !standardDefaults.bool(forKey: ranKey) else { return }
        run(baseDirectoryURL: baseDirectoryURL, standardDefaults: standardDefaults)
        standardDefaults.set(true, forKey: ranKey)
    }

    public static func run(
        baseDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        standardDefaults: UserDefaults = .standard
    ) {
        let claudeDir = baseDirectoryURL.appending(path: ".claude")
        let hooksDir = claudeDir.appending(path: "hooks")
        let settingsURL = claudeDir.appending(path: "settings.json")
        pruneSettings(at: settingsURL, hooksDir: hooksDir)
        removePerchHookScripts(in: hooksDir)
        wipePerchDefaults(standardDefaults: standardDefaults)
    }

    private static func pruneSettings(at settingsURL: URL, hooksDir: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsURL.path),
              let data = try? Data(contentsOf: settingsURL),
              var root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var hooks = root["hooks"] as? [String: Any] else { return }

        let perchCommandPrefix = hooksDir.path + "/perch-hook"

        for (event, value) in hooks {
            guard var entries = value as? [[String: Any]] else { continue }
            entries = entries.compactMap { entry in
                var entry = entry
                var nested = entry["hooks"] as? [[String: Any]] ?? []
                nested.removeAll { hook in
                    if hook["_perch"] as? Bool == true { return true }
                    if hook["_perchVersion"] != nil { return true }
                    if let cmd = hook["command"] as? String, cmd.hasPrefix(perchCommandPrefix) { return true }
                    return false
                }
                if nested.isEmpty { return nil }
                entry["hooks"] = nested
                return entry
            }
            hooks[event] = entries.isEmpty ? nil : entries
        }
        root["hooks"] = hooks.isEmpty ? nil : hooks

        guard JSONSerialization.isValidJSONObject(root) else { return }
        guard let out = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return }
        try? out.write(to: settingsURL, options: .atomic)
    }

    private static func removePerchHookScripts(in hooksDir: URL) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: hooksDir, includingPropertiesForKeys: nil) else { return }
        for entry in entries where entry.lastPathComponent.hasPrefix("perch-hook") {
            try? fm.removeItem(at: entry)
        }
    }

    private static func wipePerchDefaults(standardDefaults: UserDefaults) {
        guard let suite = UserDefaults(suiteName: "com.perch.app") else { return }
        var preserved: [String: Any] = [:]
        for key in preserveKeys {
            if let value = suite.object(forKey: key) {
                preserved[key] = value
            }
        }
        suite.removePersistentDomain(forName: "com.perch.app")
        for (key, value) in preserved {
            suite.set(value, forKey: key)
        }
    }
}
