import SwiftUI

public struct MenuBarScene: Scene {
    let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public var body: some Scene {
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
