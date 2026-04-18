import SwiftUI

struct FamiliarSpriteView: View {
    let familiar: any Familiar
    let theme: PerchTheme
    let state: FamiliarState

    private let frameProvider = SpriteFrameProvider()
    private let renderer = SpriteAccentRenderer()

    var body: some View {
        renderer.image(for: frameProvider.image(named: familiar.frameAssetName(for: state)))
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(theme.accent.primaryColor)
    }
}
