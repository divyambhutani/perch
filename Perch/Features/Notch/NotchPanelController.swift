import AppKit
import SwiftUI

@MainActor
final class NotchPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        let rootView = AnyView(content())

        if let hostingView, let panel {
            hostingView.rootView = rootView
            let fittingSize = hostingView.fittingSize
            panel.setContentSize(
                NSSize(width: max(360, fittingSize.width), height: max(180, fittingSize.height))
            )
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: rootView)
        let fittingSize = hostingView.fittingSize

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(
                    x: 0,
                    y: 0,
                    width: max(360, fittingSize.width),
                    height: max(180, fittingSize.height)
                ),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.contentMinSize = NSSize(width: 360, height: 180)
            panel.contentView = hostingView
            self.panel = panel
            self.hostingView = hostingView
        }

        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
