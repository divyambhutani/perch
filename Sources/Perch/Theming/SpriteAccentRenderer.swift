import AppKit
import CoreGraphics
import SwiftUI

// Accent-only runtime LUT. Body pixels keep their baked tones; accent pixels
// (authored as pure white or pure magenta) get replaced with the theme's
// primary / secondary colors. Cache is actor-isolated so calls from MainActor
// + background renderers stay safe.

actor SpriteAccentRenderer {
    struct Key: Hashable, Sendable {
        let mascot: MascotID
        let state: FamiliarState
        let themeID: String
        let appearance: Int
    }

    private var cache: [Key: [CGImage]] = [:]

    // Authored accent markers, premultipliedLast:
    //   primary   = pure white   (0xFF, 0xFF, 0xFF, 0xFF) → theme.primary
    //   secondary = pure magenta (0xFF, 0x00, 0xFF, 0xFF) → theme.secondary

    func frames(
        for descriptor: SpriteDescriptor,
        mascot: MascotID,
        state: FamiliarState,
        theme: PerchTheme,
        appearance: NSAppearance.Name
    ) throws -> [CGImage] {
        let key = Key(
            mascot: mascot,
            state: state,
            themeID: theme.id,
            appearance: appearance == .darkAqua ? 1 : 0
        )
        if let cached = cache[key] { return cached }

        let url = try resourceURL(descriptor: descriptor, state: state)
        let strip = try loadCGImage(url: url)
        let tinted = try tintAccentPixels(in: strip, to: theme.accent)
        let sliced = try slice(tinted, frameCount: descriptor.frameCount)
        cache[key] = sliced
        return sliced
    }

    func reset() { cache.removeAll() }

    private func resourceURL(descriptor: SpriteDescriptor, state: FamiliarState) throws -> URL {
        let subdir = descriptor.resourceSubdirectory
        let name = state.rawValue
        // Xcode preserves the Resources/ hierarchy; SwiftPM .process flattens it.
        if let url = PerchBundle.resources.url(
            forResource: name,
            withExtension: "png",
            subdirectory: subdir
        ) { return url }
        if let url = PerchBundle.resources.url(
            forResource: name,
            withExtension: "png"
        ) { return url }
        throw SpriteAccentRendererError.resourceMissing(subdir: subdir, state: state)
    }

    private func loadCGImage(url: URL) throws -> CGImage {
        let data = try Data(contentsOf: url)
        guard
            let rep = NSBitmapImageRep(data: data),
            let cg = rep.cgImage
        else {
            throw SpriteAccentRendererError.decodeFailed(url)
        }
        return cg
    }

    private func tintAccentPixels(in image: CGImage, to palette: ThemeAccentPalette) throws -> CGImage {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
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
            throw SpriteAccentRendererError.contextAllocFailed
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let primary = RGBA(
            r: UInt8(palette.primaryRed * 255),
            g: UInt8(palette.primaryGreen * 255),
            b: UInt8(palette.primaryBlue * 255),
            a: 0xFF
        )
        let secondary = RGBA(
            r: UInt8(palette.secondaryRed * 255),
            g: UInt8(palette.secondaryGreen * 255),
            b: UInt8(palette.secondaryBlue * 255),
            a: 0xFF
        )

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = buffer[offset]
                let g = buffer[offset + 1]
                let b = buffer[offset + 2]
                let a = buffer[offset + 3]
                guard a == 0xFF else { continue }
                // premultipliedLast — white marker stored (a,a,a,a); magenta (a,0,a,a).
                if r == a && g == a && b == a {
                    buffer[offset]     = primary.r
                    buffer[offset + 1] = primary.g
                    buffer[offset + 2] = primary.b
                } else if r == a && g == 0 && b == a {
                    buffer[offset]     = secondary.r
                    buffer[offset + 1] = secondary.g
                    buffer[offset + 2] = secondary.b
                }
            }
        }

        guard let tinted = ctx.makeImage() else {
            throw SpriteAccentRendererError.contextAllocFailed
        }
        return tinted
    }

    private func slice(_ strip: CGImage, frameCount: Int) throws -> [CGImage] {
        precondition(frameCount > 0)
        let frameW = strip.width / frameCount
        return try (0..<frameCount).map { idx in
            let rect = CGRect(x: idx * frameW, y: 0, width: frameW, height: strip.height)
            guard let frame = strip.cropping(to: rect) else {
                throw SpriteAccentRendererError.sliceFailed(index: idx)
            }
            return frame
        }
    }

    private struct RGBA: Equatable {
        let r: UInt8; let g: UInt8; let b: UInt8; let a: UInt8
    }
}

enum SpriteAccentRendererError: Error, Sendable {
    case resourceMissing(subdir: String, state: FamiliarState)
    case decodeFailed(URL)
    case contextAllocFailed
    case sliceFailed(index: Int)
}
