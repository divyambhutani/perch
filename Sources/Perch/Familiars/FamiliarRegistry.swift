import Foundation

public struct FamiliarRegistry: Sendable {
    private let familiars: [MascotID: any Familiar]

    init(familiars: [any Familiar]) {
        self.familiars = Dictionary(uniqueKeysWithValues: familiars.map { ($0.id, $0) })
    }

    func familiar(for id: MascotID) -> any Familiar {
        familiars[id] ?? SenecaFamiliar()
    }

    static func defaultRegistry() -> FamiliarRegistry {
        FamiliarRegistry(familiars: [SenecaFamiliar()])
    }
}
