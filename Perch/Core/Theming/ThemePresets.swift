import SwiftUI

enum ThemePresets {
    static let defaultTheme = PerchTheme(
        id: "default",
        accent: ThemeAccentPalette(
            primaryRed: 0.94,
            primaryGreen: 0.79,
            primaryBlue: 0.18,
            secondaryRed: 0.87,
            secondaryGreen: 0.55,
            secondaryBlue: 0.12
        )
    )

    static let midnight = PerchTheme(
        id: "midnight",
        accent: ThemeAccentPalette(
            primaryRed: 0.32,
            primaryGreen: 0.82,
            primaryBlue: 0.89,
            secondaryRed: 0.10,
            secondaryGreen: 0.28,
            secondaryBlue: 0.64
        )
    )

    static let teal = PerchTheme(
        id: "teal",
        accent: ThemeAccentPalette(
            primaryRed: 0.11,
            primaryGreen: 0.67,
            primaryBlue: 0.61,
            secondaryRed: 0.51,
            secondaryGreen: 0.85,
            secondaryBlue: 0.74
        )
    )

    static let plum = PerchTheme(
        id: "plum",
        accent: ThemeAccentPalette(
            primaryRed: 0.49,
            primaryGreen: 0.25,
            primaryBlue: 0.56,
            secondaryRed: 0.82,
            secondaryGreen: 0.49,
            secondaryBlue: 0.65
        )
    )

    static let pewter = PerchTheme(
        id: "pewter",
        accent: ThemeAccentPalette(
            primaryRed: 0.49,
            primaryGreen: 0.51,
            primaryBlue: 0.54,
            secondaryRed: 0.72,
            secondaryGreen: 0.74,
            secondaryBlue: 0.77
        )
    )

    static let highContrast = PerchTheme(
        id: "highContrast",
        accent: ThemeAccentPalette(
            primaryRed: 1.0,
            primaryGreen: 0.91,
            primaryBlue: 0.0,
            secondaryRed: 0.0,
            secondaryGreen: 0.0,
            secondaryBlue: 0.0
        )
    )

    static let all: [PerchTheme] = [
        defaultTheme,
        midnight,
        teal,
        plum,
        pewter,
        highContrast
    ]
}
