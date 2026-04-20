import Foundation
import Testing
@testable import Perch

struct PerchStringsLintTests {
    @Test
    func featuresDoNotHardcodeUserFacingStrings() throws {
        let featuresRoot = Self.featuresDirectory()
        let files = try Self.swiftFiles(in: featuresRoot)

        var offenders: [String] = []
        let pattern = #"(Text|Label|Button)\(\s*"[^"]+""#
        for file in files {
            let contents = try String(contentsOf: file, encoding: .utf8)
            let scrubbed = Self.stripDebugPreviews(contents)
            if scrubbed.range(of: pattern, options: .regularExpression) != nil {
                offenders.append(file.lastPathComponent)
            }
        }

        #expect(offenders.isEmpty, "Hardcoded Text/Label/Button literal outside #if DEBUG preview: \(offenders)")
    }

    private static func stripDebugPreviews(_ source: String) -> String {
        var result: [Substring] = []
        var skip = false
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.contains("#if DEBUG") { skip = true; continue }
            if skip && line.contains("#endif") { skip = false; continue }
            if !skip { result.append(line) }
        }
        return result.joined(separator: "\n")
    }

    private static func featuresDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Perch/Features", isDirectory: true)
    }

    private static func swiftFiles(in root: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else { return [] }
        var out: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            out.append(url)
        }
        return out
    }
}
