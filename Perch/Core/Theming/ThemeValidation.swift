import Foundation

enum ThemeValidation {
    static func validate(theme: PerchTheme) -> Bool {
        !theme.id.isEmpty
    }
}
