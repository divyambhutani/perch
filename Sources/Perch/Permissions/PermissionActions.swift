import Foundation

@MainActor
struct PermissionActions {
    let approve: (PermissionRequest.ID) -> Void
}
