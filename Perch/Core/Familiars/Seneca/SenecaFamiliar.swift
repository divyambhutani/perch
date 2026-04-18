import Foundation

struct SenecaFamiliar: Familiar {
    let id: MascotID = .seneca
    let displayName = "Seneca"
    let tone = SenecaTone.value

    func frameAssetName(for state: FamiliarState) -> String {
        "Mascots/Seneca/\(state.rawValue)"
    }
}
