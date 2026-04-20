import Testing
@testable import Perch

@MainActor
struct MenuBarSceneTests {
    @Test
    func previewEnvironmentBuilds() {
        let environment = AppEnvironment.preview()

        #expect(environment.sessionStore.sessions.count == 1)
    }
}
