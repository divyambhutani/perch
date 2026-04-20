import Foundation
import Testing
@testable import Perch

@MainActor
struct OnboardingCoordinatorTests {
    @Test
    func freshCoordinatorStartsAtWelcome() {
        let defaults = Self.makeDefaults()
        let coordinator = OnboardingCoordinator(defaults: defaults)

        #expect(coordinator.currentStep == .welcome)
        #expect(coordinator.isCompleted == false)
    }

    @Test
    func advanceWalksEachStepInOrder() {
        let coordinator = OnboardingCoordinator(defaults: Self.makeDefaults())
        let expected: [OnboardingCoordinator.Step] = [
            .launchAtLogin, .fileAccess, .hooks, .complete
        ]

        var observed: [OnboardingCoordinator.Step] = []
        for _ in expected {
            coordinator.advance()
            observed.append(coordinator.currentStep)
        }

        #expect(observed == expected)

        coordinator.advance()
        #expect(coordinator.currentStep == .complete)
    }

    @Test
    func finishPersistsCompletion() {
        let defaults = Self.makeDefaults()
        let coordinator = OnboardingCoordinator(defaults: defaults)

        var didInvoke = false
        coordinator.setCompletionHandler { didInvoke = true }
        coordinator.finish()

        #expect(coordinator.isCompleted == true)
        #expect(coordinator.isPresenting == false)
        #expect(defaults.bool(forKey: OnboardingCoordinator.defaultsKey) == true)
        #expect(didInvoke == true)
    }

    @Test
    func initReadsPersistedCompletion() {
        let defaults = Self.makeDefaults()
        defaults.set(true, forKey: OnboardingCoordinator.defaultsKey)

        let coordinator = OnboardingCoordinator(defaults: defaults)
        #expect(coordinator.isCompleted == true)
    }

    @Test
    func skipAdvancesWithoutMarkingGrants() {
        let coordinator = OnboardingCoordinator(defaults: Self.makeDefaults())
        coordinator.advance()
        #expect(coordinator.currentStep == .launchAtLogin)

        coordinator.skip()

        #expect(coordinator.currentStep == .fileAccess)
        #expect(coordinator.launchAtLoginGranted == false)
    }

    @Test
    func resetForReRunClearsPersistedFlag() {
        let defaults = Self.makeDefaults()
        defaults.set(true, forKey: OnboardingCoordinator.defaultsKey)
        let coordinator = OnboardingCoordinator(defaults: defaults)

        coordinator.resetForReRun()

        #expect(coordinator.isCompleted == false)
        #expect(coordinator.currentStep == .welcome)
        #expect(defaults.object(forKey: OnboardingCoordinator.defaultsKey) == nil)
    }

    private static func makeDefaults() -> UserDefaults {
        let suite = "com.perch.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
