import Foundation

struct SenecaFamiliar: Familiar {
    let id: MascotID = .seneca
    let displayName = "Seneca"
    let tone = SenecaTone.value
    let spriteDescriptor = SpriteDescriptor.seneca

    func frameAssetName(for state: FamiliarState) -> String {
        "\(spriteDescriptor.resourceSubdirectory)/\(state.rawValue)"
    }
}
