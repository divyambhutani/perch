import Foundation

struct SpriteDescriptor: Sendable, Hashable {
    let resourceSubdirectory: String
    let frameWidth: Int
    let frameHeight: Int
    let frameCount: Int

    static let seneca = SpriteDescriptor(
        resourceSubdirectory: "Mascots/Seneca",
        frameWidth: 40,
        frameHeight: 44,
        frameCount: 2
    )
}
