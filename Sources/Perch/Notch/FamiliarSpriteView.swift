import AppKit
import SwiftUI

// 2-frame sprite at 500 ms cadence. Uses CoreAnimation (CAKeyframeAnimation on
// `contents`) so the SwiftUI body never re-evaluates per frame — plan §3b: the
// TimelineView path caused jank on notch rendering.

struct FamiliarSpriteView: View {
    let familiar: any Familiar
    let theme: PerchTheme
    let state: FamiliarState

    var body: some View {
        SpriteLayerHost(
            descriptor: familiar.spriteDescriptor,
            mascot: familiar.id,
            state: state,
            theme: theme
        )
    }
}

private struct SpriteLayerHost: NSViewRepresentable {
    let descriptor: SpriteDescriptor
    let mascot: MascotID
    let state: FamiliarState
    let theme: PerchTheme

    func makeNSView(context: Context) -> SpriteLayerView {
        SpriteLayerView()
    }

    func updateNSView(_ nsView: SpriteLayerView, context: Context) {
        nsView.apply(descriptor: descriptor, mascot: mascot, state: state, theme: theme)
    }
}

final class SpriteLayerView: NSView {
    private let renderer = SpriteAccentRenderer()
    private let frameDuration: CFTimeInterval = 0.5
    private let animationKey = "perch.sprite.frames"

    private var currentKey: SpriteAccentRenderer.Key?
    private var loadTask: Task<Void, Never>?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.contentsGravity = .resizeAspect
        layer?.magnificationFilter = .nearest
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    override var intrinsicContentSize: NSSize { NSSize(width: 18, height: 18) }

    func apply(descriptor: SpriteDescriptor, mascot: MascotID, state: FamiliarState, theme: PerchTheme) {
        let appearance = effectiveAppearance.name
        let key = SpriteAccentRenderer.Key(
            mascot: mascot,
            state: state,
            themeID: theme.id,
            appearance: appearance == .darkAqua ? 1 : 0
        )
        guard key != currentKey else { return }
        currentKey = key

        loadTask?.cancel()
        let rendererRef = renderer
        loadTask = Task { [weak self] in
            guard let self else { return }
            let frames = (try? await rendererRef.frames(
                for: descriptor,
                mascot: mascot,
                state: state,
                theme: theme,
                appearance: appearance
            )) ?? []
            await MainActor.run { self.install(frames: frames) }
        }
    }

    private func install(frames: [CGImage]) {
        guard let layer else { return }
        layer.removeAnimation(forKey: animationKey)
        guard !frames.isEmpty else {
            layer.contents = nil
            return
        }
        layer.contents = frames[0]
        guard frames.count > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.keyTimes = frames.enumerated().map { idx, _ in
            NSNumber(value: Double(idx) / Double(frames.count))
        }
        animation.calculationMode = .discrete
        animation.duration = frameDuration * CFTimeInterval(frames.count)
        animation.repeatCount = .greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: animationKey)
    }
}
