import AppKit
import SwiftUI

@MainActor
public final class NotchMascotOverlayController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    public init() {}

    public var isVisible: Bool { panel?.isVisible == true }

    public func show<Content: View>(@ViewBuilder content: () -> Content) {
        guard screenHasNotch() else {
            hide()
            return
        }
        let rootView = AnyView(content())

        if let panel, let hostingView {
            hostingView.rootView = rootView
            reposition(panel: panel)
            panel.orderFrontRegardless()
            return
        }

        let hosting = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 56, height: 28),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .transient, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = hosting
        self.panel = panel
        self.hostingView = hosting

        reposition(panel: panel)
        panel.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    public var panelFrame: NSRect? { panel?.frame }

    private func screenHasNotch() -> Bool {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return false }
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }

    private func reposition(panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let notchInset: CGFloat
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            notchInset = screen.safeAreaInsets.top
        } else {
            notchInset = 28
        }
        let height = max(24, notchInset)
        let width: CGFloat = 56
        panel.setContentSize(NSSize(width: width, height: height))
        let x = screen.frame.midX - width / 2
        let y = screen.frame.maxY - height
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
