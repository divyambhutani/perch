import Foundation
import Sparkle

@MainActor
public final class UpdaterController {
    private let controller: SPUStandardUpdaterController?

    init(bundle: Bundle = .main) {
        if bundle.object(forInfoDictionaryKey: "SUFeedURL") != nil {
            controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            controller = nil
        }
    }

    var isConfigured: Bool {
        controller != nil
    }

    var canCheckForUpdates: Bool {
        controller?.updater.canCheckForUpdates ?? false
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
