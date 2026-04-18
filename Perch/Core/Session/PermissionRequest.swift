import Foundation

struct PermissionRequest: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var summary: String
    var diffPreview: String

    init(id: UUID = UUID(), summary: String, diffPreview: String) {
        self.id = id
        self.summary = summary
        self.diffPreview = diffPreview
    }
}
