import AppKit
import SwiftUI

struct SpriteAccentRenderer {
    func image(for source: NSImage?) -> Image {
        if let source {
            return Image(nsImage: source)
        }

        return Image(systemName: "bird")
    }
}
