import Foundation
import Observation

@MainActor
@Observable
public final class OnboardingCoordinator {
    public enum Step: Int, CaseIterable, Sendable {
        case welcome
        case launchAtLogin
        case fileAccess
        case hooks
        case complete
    }

    public static let defaultsKey = "onboarding.v1.completed"
    public static let defaultsSuite = "com.perch.app"

    public private(set) var currentStep: Step
    public private(set) var launchAtLoginGranted: Bool
    public private(set) var fileAccessAcknowledged: Bool
    public private(set) var hooksInstalled: Bool
    public private(set) var isCompleted: Bool
    public private(set) var isPresenting: Bool

    private let defaults: UserDefaults
    private var onComplete: (@MainActor () -> Void)?

    public init(defaults: UserDefaults = OnboardingCoordinator.makeDefaults()) {
        self.defaults = defaults
        self.currentStep = .welcome
        self.launchAtLoginGranted = false
        self.fileAccessAcknowledged = false
        self.hooksInstalled = false
        self.isCompleted = defaults.bool(forKey: Self.defaultsKey)
        self.isPresenting = false
    }

    public static func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: defaultsSuite) ?? .standard
    }

    public func setCompletionHandler(_ handler: @escaping @MainActor () -> Void) {
        onComplete = handler
    }

    public func markLaunchAtLoginGranted(_ granted: Bool) {
        launchAtLoginGranted = granted
    }

    public func markFileAccessAcknowledged() {
        fileAccessAcknowledged = true
    }

    public func markHooksInstalled(_ installed: Bool) {
        hooksInstalled = installed
    }

    public func advance() {
        guard let index = Step.allCases.firstIndex(of: currentStep),
              index + 1 < Step.allCases.count else { return }
        currentStep = Step.allCases[index + 1]
    }

    public func skip() { advance() }

    public func requestPresentation() {
        currentStep = .welcome
        isPresenting = true
    }

    public func dismissPresentation() {
        isPresenting = false
    }

    public func finish() {
        defaults.set(true, forKey: Self.defaultsKey)
        isCompleted = true
        isPresenting = false
        onComplete?()
    }

    public func resetForReRun() {
        defaults.removeObject(forKey: Self.defaultsKey)
        isCompleted = false
        currentStep = .welcome
        launchAtLoginGranted = false
        fileAccessAcknowledged = false
        hooksInstalled = false
    }
}
