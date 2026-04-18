import Foundation
import Testing
@testable import Perch

struct HookInstallerTests {
    @Test
    func computesClaudeHooksPath() {
        let installer = HookInstaller()

        #expect(installer.installationURL().path.contains(".claude/hooks/perch-hook.sh"))
    }

    @Test
    func installsHookScriptAndSettings() throws {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let installer = HookInstaller(baseDirectoryURL: temporaryDirectory)
        let status = try installer.install()

        guard case .installed(let url) = status else {
            Issue.record("Expected installed status.")
            return
        }

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(FileManager.default.fileExists(atPath: installer.settingsURL().path))
    }
}
