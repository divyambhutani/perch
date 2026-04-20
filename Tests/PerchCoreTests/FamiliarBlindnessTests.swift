import Foundation
import Testing
@testable import Perch

struct FamiliarBlindnessTests {
    @Test
    func featuresHaveNoDirectMascotReferences() throws {
        let root = Self.featuresRoot()
        let files = try Self.swiftFiles(in: root)
        #expect(!files.isEmpty, "Features directory should contain Swift files")

        var offenders: [String] = []
        for file in files {
            let contents = try String(contentsOf: file, encoding: .utf8)
            if contents.range(of: #"\.seneca\b"#, options: .regularExpression) != nil {
                offenders.append(file.lastPathComponent)
            }
        }

        #expect(offenders.isEmpty, "Features are not allowed to reference a specific mascot id: \(offenders)")
    }

    @Test
    func defaultRegistryResolvesSeneca() {
        let registry = FamiliarRegistry.defaultRegistry()
        let seneca = registry.familiar(for: .seneca)
        #expect(seneca.id == .seneca)
    }

    private static let featureSubdirectories = [
        "MenuBar", "Notch", "Permissions", "SessionList", "Settings", "Shared"
    ]

    private static func featuresRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/Perch", isDirectory: true)
    }

    private static func swiftFiles(in root: URL) throws -> [URL] {
        var out: [URL] = []
        for subdir in featureSubdirectories {
            let dir = root.appendingPathComponent(subdir, isDirectory: true)
            guard let enumerator = FileManager.default.enumerator(
                at: dir,
                includingPropertiesForKeys: nil
            ) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "swift" {
                out.append(url)
            }
        }
        return out
    }
}
