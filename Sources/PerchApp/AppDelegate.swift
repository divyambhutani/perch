import AppKit
import Perch
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let notchController = NotchPanelController()
    private let notchOverlayController = NotchMascotOverlayController()
    private let sessionsPanelController = SessionsPanelController()
    private let hotkeyController = SessionHotkeyController()
    private(set) var environment: AppEnvironment = AppBootstrap.makeEnvironment()
    private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PerchCleanupMigrator.runOnce()
        Task { @MainActor [environment] in
            await environment.startServices()
            if environment.onboardingCoordinator.isCompleted {
                environment.installHooks()
            }
        }
        hotkeyController.register { [weak self] in
            self?.presentNotchPanel()
        }

        let coordinator = environment.onboardingCoordinator
        coordinator.setCompletionHandler { [weak self] in
            self?.handleOnboardingFinished()
        }
        environment.setPresentOnboardingHandler { [weak self] in
            self?.presentOnboarding()
        }
        environment.setSessionsPanelHandler { [weak self] visible in
            self?.handleSessionsPanel(visible: visible)
        }
        environment.setNotchMascotPlacementHandler { [weak self] _ in
            self?.presentNotchPanel()
        }

        if coordinator.isCompleted {
            presentNotchPanel()
            environment.startSessionDiscovery()
        } else {
            presentOnboarding()
        }
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        guard environment.onboardingCoordinator.isCompleted else { return }
        presentNotchPanel()
    }

    private func presentNotchPanel() {
        if environment.notchMascotInsideNotch && screenHasNotch() {
            notchController.hide()
            notchOverlayController.show {
                NotchPanelHost(compact: true)
                    .environment(self.environment)
            }
        } else {
            notchOverlayController.hide()
            notchController.show {
                NotchPanelHost()
                    .environment(self.environment)
            }
        }
    }

    private func screenHasNotch() -> Bool {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return false }
        if #available(macOS 12.0, *) { return screen.safeAreaInsets.top > 0 }
        return false
    }

    private func presentOnboarding() {
        let controller = onboardingWindowController ?? OnboardingWindowController(
            coordinator: environment.onboardingCoordinator,
            environment: environment
        )
        onboardingWindowController = controller
        controller.present()
    }

    private func handleOnboardingFinished() {
        onboardingWindowController?.dismiss()
        presentNotchPanel()
        environment.startSessionDiscovery()
    }

    private func handleSessionsPanel(visible: Bool) {
        if visible {
            guard let anchor = mascotAnchor() else { return }
            sessionsPanelController.show(
                anchor: anchor,
                onOutsideClick: { [weak self] in
                    self?.environment.setSessionsPanelVisible(false)
                }
            ) {
                SessionsPanelHost()
                    .environment(self.environment)
            }
        } else {
            sessionsPanelController.hide()
        }
    }

    private func mascotAnchor() -> NSRect? {
        if environment.notchMascotInsideNotch, let frame = notchOverlayController.panelFrame {
            return frame
        }
        return notchController.panelFrame
    }
}
