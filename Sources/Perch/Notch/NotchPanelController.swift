import AppKit
import SwiftUI

@MainActor
public final class NotchPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    public init() {}

    public func show<Content: View>(@ViewBuilder content: () -> Content) {
        let rootView = AnyView(content())

        if let hostingView, let panel {
            hostingView.rootView = rootView
            resize(panel: panel, fitting: hostingView.fittingSize)
            reposition(panel: panel)
            panel.orderFrontRegardless()
            return
        }

        let hosting = NSHostingView(rootView: rootView)
        let size = hosting.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: max(80, size.width), height: max(80, size.height)),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .transient, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentMinSize = NSSize(width: 80, height: 80)
        panel.contentView = hosting
        self.panel = panel
        self.hostingView = hosting

        reposition(panel: panel)
        panel.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    private func resize(panel: NSPanel, fitting size: NSSize) {
        panel.setContentSize(NSSize(width: max(80, size.width), height: max(80, size.height)))
    }

    public var panelFrame: NSRect? { panel?.frame }

    private func reposition(panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let contentSize = panel.frame.size
        let notchInset: CGFloat
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            notchInset = screen.safeAreaInsets.top
        } else {
            notchInset = 0
        }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.midX - contentSize.width / 2
        let y = visibleFrame.maxY - contentSize.height - max(0, notchInset - 6)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
