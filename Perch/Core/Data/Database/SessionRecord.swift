import Foundation
import GRDB

struct SessionRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    let id: String
    let title: String
    let state: String
    let updatedAt: Date
}
