import AppKit
import SwiftUI

@MainActor
public final class SessionsPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var dismissMonitor: Any?
    private var onOutsideClick: (() -> Void)?

    public init() {}

    public func show<Content: View>(
        anchor: NSRect,
        onOutsideClick: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onOutsideClick = onOutsideClick
        let rootView = AnyView(content())

        if let panel, let hostingView {
            hostingView.rootView = rootView
            reposition(panel: panel, anchor: anchor, fitting: hostingView.fittingSize)
            panel.orderFrontRegardless()
            installMonitor()
            return
        }

        let hosting = NSHostingView(rootView: rootView)
        let size = hosting.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentView = hosting

        self.panel = panel
        self.hostingView = hosting
        reposition(panel: panel, anchor: anchor, fitting: size)
        panel.orderFrontRegardless()
        installMonitor()
    }

    public func hide() {
        panel?.orderOut(nil)
        removeMonitor()
    }

    private func installMonitor() {
        removeMonitor()
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.onOutsideClick?()
            }
        }
    }

    private func removeMonitor() {
        if let dismissMonitor {
            NSEvent.removeMonitor(dismissMonitor)
        }
        dismissMonitor = nil
    }

    private func reposition(panel: NSPanel, anchor: NSRect, fitting size: NSSize) {
        panel.setContentSize(size)
        let gap: CGFloat = 6
        let x = anchor.midX - size.width / 2
        let y = anchor.minY - size.height - gap
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
