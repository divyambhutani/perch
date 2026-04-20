import Foundation

protocol Familiar: Sendable {
    var id: MascotID { get }
    var displayName: String { get }
    var tone: CopyTone { get }
    var spriteDescriptor: SpriteDescriptor { get }
    func frameAssetName(for state: FamiliarState) -> String
}
