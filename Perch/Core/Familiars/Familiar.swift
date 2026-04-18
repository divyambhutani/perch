import Foundation

protocol Familiar: Sendable {
    var id: MascotID { get }
    var displayName: String { get }
    var tone: CopyTone { get }
    func frameAssetName(for state: FamiliarState) -> String
}
