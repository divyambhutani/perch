import AppKit
import Testing
@testable import Perch

struct SpritePaletteValidationTests {
    // Walks every PNG under Sources/Perch/Resources/Mascots and asserts each
    // non-transparent pixel belongs to the fixed body palette (4 tones) or one
    // of two accent markers (primary=white, secondary=magenta) which the
    // runtime LUT in SpriteAccentRenderer swaps to theme colors (plan §2b).
    @Test
    func everyMascotPNGUsesOnlyBodyOrAccent() throws {
        let mascotsDir = Self.mascotsDirectory()
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: mascotsDir, includingPropertiesForKeys: nil) else {
            Issue.record("mascots directory not found at \(mascotsDir.path)")
            return
        }

        let head      = RGBA(r: 0x3F, g: 0x42, b: 0x4A, a: 0xFF)
        let face      = RGBA(r: 0xC8, g: 0xC4, b: 0xBA, a: 0xFF)
        let cheek     = RGBA(r: 0x6E, g: 0x70, b: 0x78, a: 0xFF)
        let pupil     = RGBA(r: 0x00, g: 0x00, b: 0x00, a: 0xFF)
        let primary   = RGBA(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF)
        let secondary = RGBA(r: 0xFF, g: 0x00, b: 0xFF, a: 0xFF)

        var checked = 0
        for case let url as URL in enumerator where url.pathExtension.lowercased() == "png" {
            let offenders = try offendingPixels(url: url, allowed: [head, face, cheek, pupil, primary, secondary])
            #expect(offenders.isEmpty, "palette drift in \(url.lastPathComponent): \(offenders.prefix(3))")
            checked += 1
        }
        #expect(checked >= 5, "expected ≥5 Seneca PNGs, got \(checked)")
    }

    private func offendingPixels(url: URL, allowed: Set<RGBA>) throws -> [RGBA] {
        let data = try Data(contentsOf: url)
        guard let rep = NSBitmapImageRep(data: data) else {
            throw NSError(domain: "SpritePalette", code: 1, userInfo: [NSLocalizedDescriptionKey: "decode \(url.lastPathComponent)"])
        }
        let width = rep.pixelsWide
        let height = rep.pixelsHigh
        var offenders: [RGBA] = []
        for y in 0..<height {
            for x in 0..<width {
                guard let color = rep.colorAt(x: x, y: y) else { continue }
                let a = UInt8(color.alphaComponent * 255)
                if a == 0 { continue }
                let pixel = RGBA(
                    r: UInt8(color.redComponent * 255),
                    g: UInt8(color.greenComponent * 255),
                    b: UInt8(color.blueComponent * 255),
                    a: a
                )
                if !allowed.contains(pixel) {
                    offenders.append(pixel)
                }
            }
        }
        return offenders
    }

    private static func mascotsDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // PerchCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("Sources")
            .appendingPathComponent("Perch")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Mascots")
    }

    struct RGBA: Hashable {
        let r: UInt8; let g: UInt8; let b: UInt8; let a: UInt8
    }
}
