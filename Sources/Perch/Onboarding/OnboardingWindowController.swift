import AppKit
import SwiftUI

@MainActor
public final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let coordinator: OnboardingCoordinator
    private let environment: AppEnvironment

    public init(coordinator: OnboardingCoordinator, environment: AppEnvironment) {
        self.coordinator = coordinator
        self.environment = environment

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = PerchStrings.onboardingWindowTitle(tone: environment.sessionStore.currentFamiliar.tone)
        window.isReleasedWhenClosed = false
        window.center()

        let host = NSHostingController(
            rootView: OnboardingRootView()
                .environment(coordinator)
                .environment(environment)
        )
        window.contentViewController = host

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func present() {
        coordinator.requestPresentation()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    public func dismiss() {
        coordinator.dismissPresentation()
        window?.orderOut(nil)
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        coordinator.currentStep == .complete || coordinator.isCompleted
    }
}
