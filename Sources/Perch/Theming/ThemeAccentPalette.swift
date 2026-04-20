import SwiftUI

struct ThemeAccentPalette: Hashable, Sendable {
    let primaryRed: Double
    let primaryGreen: Double
    let primaryBlue: Double
    let secondaryRed: Double
    let secondaryGreen: Double
    let secondaryBlue: Double

    var primaryColor: Color {
        Color(red: primaryRed, green: primaryGreen, blue: primaryBlue)
    }

    var secondaryColor: Color {
        Color(red: secondaryRed, green: secondaryGreen, blue: secondaryBlue)
    }
}
