import AppKit
import Testing
@testable import Perch

struct SpriteAccentRendererTests {
    // Verifies the LUT actually swaps accent (white) pixels to the theme's
    // primary color while leaving body pixels untouched, and yields 2 frames.
    @Test
    func accentLUTSwapsWhiteToThemePrimary() async throws {
        let renderer = SpriteAccentRenderer()
        let goldcrest = ThemePresets.all[0] // "Goldcrest"
        let frames = try await renderer.frames(
            for: .seneca,
            mascot: .seneca,
            state: .idle,
            theme: goldcrest,
            appearance: .aqua
        )

        #expect(frames.count == 2)
        let first = frames[0]
        #expect(first.width == 40 && first.height == 44)

        let samples = try pixelsOf(first)
        let expectedPrimary = (
            UInt8(goldcrest.accent.primaryRed * 255),
            UInt8(goldcrest.accent.primaryGreen * 255),
            UInt8(goldcrest.accent.primaryBlue * 255)
        )
        let expectedSecondary = (
            UInt8(goldcrest.accent.secondaryRed * 255),
            UInt8(goldcrest.accent.secondaryGreen * 255),
            UInt8(goldcrest.accent.secondaryBlue * 255)
        )

        let hasPrimary   = samples.contains { $0 == expectedPrimary }
        let hasSecondary = samples.contains { $0 == expectedSecondary }
        let hasBody      = samples.contains { $0 == (UInt8(0x3F), UInt8(0x42), UInt8(0x4A)) }
        #expect(hasPrimary,   "LUT did not produce any primary-accent pixels")
        #expect(hasSecondary, "LUT did not produce any secondary-accent pixels")
        #expect(hasBody,      "body pixels were tinted by accident")
    }

    @Test
    func cacheReuseReturnsEqualFrameIdentity() async throws {
        let renderer = SpriteAccentRenderer()
        let theme = ThemePresets.all[0]
        let first  = try await renderer.frames(for: .seneca, mascot: .seneca, state: .idle, theme: theme, appearance: .aqua)
        let second = try await renderer.frames(for: .seneca, mascot: .seneca, state: .idle, theme: theme, appearance: .aqua)
        #expect(first.count == second.count)
        for (a, b) in zip(first, second) {
            #expect(a === b, "cached frames should be reused without re-rendering")
        }
    }

    private func pixelsOf(_ image: CGImage) throws -> [(UInt8, UInt8, UInt8)] {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var buffer = [UInt8](repeating: 0, count: bytesPerRow * height)
        guard let ctx = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw NSError(domain: "SpriteAccentRendererTests", code: 1)
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var out: [(UInt8, UInt8, UInt8)] = []
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                if buffer[offset + 3] == 0 { continue }
                out.append((buffer[offset], buffer[offset + 1], buffer[offset + 2]))
            }
        }
        return out
    }
}
