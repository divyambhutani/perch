import Testing
@testable import Perch

@MainActor
struct NotchPanelIntegrationTests {
    @Test
    func panelControllerConstructs() {
        let controller = NotchPanelController()
        controller.hide()
    }
}
