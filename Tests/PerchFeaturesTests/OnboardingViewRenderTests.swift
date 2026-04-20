import SwiftUI
import Testing
@testable import Perch

@MainActor
struct OnboardingViewRenderTests {
    @Test
    func welcomeCopyRoutesThroughSenecaTone() {
        let tone = SenecaTone.value
        let title = PerchStrings.onboardingWelcomeTitle(tone: tone)
        let body = PerchStrings.onboardingWelcomeBody(tone: tone)

        #expect(title == tone.onboardingWelcomeTitle)
        #expect(body == tone.onboardingWelcomeBody)
        #expect(title.isEmpty == false)
        #expect(body.isEmpty == false)
    }

    @Test
    func stepViewsInstantiateWithEnvironment() {
        let environment = AppEnvironment.preview()
        let coordinator = environment.onboardingCoordinator

        let rootView = OnboardingRootView()
            .environment(coordinator)
            .environment(environment)
        let hosting = NSHostingController(rootView: rootView)
        hosting.view.layoutSubtreeIfNeeded()

        #expect(hosting.view.fittingSize.width > 0)
        #expect(hosting.view.fittingSize.height > 0)
    }

    @Test
    func onboardingCopyCoversAllSteps() {
        let tone = SenecaTone.value
        let all: [String] = [
            tone.onboardingWelcomeTitle,
            tone.onboardingLaunchAtLoginTitle,
            tone.onboardingFileAccessTitle,
            tone.onboardingHooksTitle,
            tone.onboardingCompleteTitle,
            tone.onboardingContinue,
            tone.onboardingOpenPerch
        ]
        #expect(all.allSatisfy { !$0.isEmpty })
    }
}
