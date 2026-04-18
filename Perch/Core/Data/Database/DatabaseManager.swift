import Foundation
import GRDB

actor DatabaseManager {
    private let dbQueue: DatabaseQueue

    init(path: String = ":memory:") {
        do {
            dbQueue = try DatabaseQueue(path: path)
            try DatabaseMigrations.migrator.migrate(dbQueue)
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    func save(_ record: SessionRecord) throws {
        try dbQueue.write { db in
            try record.save(db)
        }
    }

    func fetchSessions() throws -> [SessionRecord] {
        try dbQueue.read { db in
            try SessionRecord.fetchAll(db)
        }
    }
}
