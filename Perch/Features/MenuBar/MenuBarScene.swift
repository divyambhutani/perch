import SwiftUI

struct MenuBarScene: Scene {
    let environment: AppEnvironment

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView()
                .environment(environment)
        } label: {
            MenuBarIconView()
                .environment(environment)
        }
        .menuBarExtraStyle(.window)
    }
}
