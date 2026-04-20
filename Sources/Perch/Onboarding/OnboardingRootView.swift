import SwiftUI

struct OnboardingRootView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            OnboardingProgressDots(currentStep: coordinator.currentStep)
                .padding(.bottom, 20)
        }
        .frame(width: 520, height: 420)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.currentStep {
        case .welcome: WelcomeStepView()
        case .launchAtLogin: LaunchAtLoginStepView()
        case .fileAccess: FileAccessStepView()
        case .hooks: HooksStepView()
        case .complete: CompleteStepView()
        }
    }
}

private struct OnboardingProgressDots: View {
    let currentStep: OnboardingCoordinator.Step

    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingCoordinator.Step.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
