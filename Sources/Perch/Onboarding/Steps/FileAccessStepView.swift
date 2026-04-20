import SwiftUI

struct FileAccessStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let tone = environment.sessionStore.currentFamiliar.tone

        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.onboardingFileAccessTitle(tone: tone))
                .font(.title2.weight(.semibold))
            Text(PerchStrings.onboardingFileAccessBody(tone: tone))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Spacer()
                Button(PerchStrings.onboardingUnderstood(tone: tone)) {
                    coordinator.markFileAccessAcknowledged()
                    coordinator.advance()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
