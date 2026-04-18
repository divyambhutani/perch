import Testing
@testable import Perch

@MainActor
struct SessionListTests {
    @Test
    func storeExposesPlaceholderSession() {
        let store = SessionStore(
            currentFamiliar: SenecaFamiliar(),
            currentTheme: ThemePresets.defaultTheme
        )

        #expect(store.sessions.first?.title == "Primary Session")
    }
}
