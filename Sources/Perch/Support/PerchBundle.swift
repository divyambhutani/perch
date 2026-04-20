import Foundation

enum PerchBundle {
    static var resources: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
}
