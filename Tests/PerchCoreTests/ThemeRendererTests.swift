import Testing
@testable import Perch

struct ThemeRendererTests {
    @Test
    func validatesPresetThemes() {
        for theme in ThemePresets.all {
            #expect(ThemeValidation.validate(theme: theme))
        }
    }
}
