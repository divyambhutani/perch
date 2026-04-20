import Foundation

enum SenecaTone {
    static let value = CopyTone(
        permissionRequired: "Permission required.",
        noPendingPermissions: "Nothing requires review.",
        sessionListTitle: "Sessions",
        settingsTitle: "Settings",
        launchAtLogin: "Launch at login",
        installHooks: "Install hooks",
        overlaySubtitle: "State changes surface here.",
        onboardingWelcomeTitle: "Meet Seneca.",
        onboardingWelcomeBody: "Perch watches Claude Code sessions from the menu bar. Three short steps to set it up.",
        onboardingLaunchAtLoginTitle: "Launch at login.",
        onboardingLaunchAtLoginBody: "Start Perch when you log in. It stays in the menu bar until you quit.",
        onboardingFileAccessTitle: "Read Claude transcripts.",
        onboardingFileAccessBody: "Perch reads ~/.claude/projects to follow live sessions. Nothing leaves this machine.",
        onboardingHooksTitle: "Install hooks.",
        onboardingHooksBody: "Perch writes ~/.claude/hooks/perch-hook.sh and entries in ~/.claude/settings.json. Skip for read-only mode.",
        onboardingCompleteTitle: "Ready.",
        onboardingCompleteBody: "Run claude in a terminal. Seneca reacts when a session starts.",
        onboardingContinue: "Continue",
        onboardingSkip: "Skip",
        onboardingUnderstood: "Understood",
        onboardingInstallHooks: "Install hooks",
        onboardingOpenPerch: "Open Perch",
        onboardingResetAction: "Run setup again",
        onboardingWindowTitle: "Welcome to Perch",
        notchInsideToggle: "Show Seneca in notch",
        quitPerch: "Quit Perch"
    )
}
