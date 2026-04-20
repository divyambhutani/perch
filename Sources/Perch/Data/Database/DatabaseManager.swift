import Foundation
import GRDB

public actor DatabaseManager {
    enum Location: Sendable {
        case memory
        case file(URL)

        static var defaultAppSupport: Location {
            let fm = FileManager.default
            let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let dir = base.appendingPathComponent("Perch", isDirectory: true)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return .file(dir.appendingPathComponent("cache.sqlite"))
        }
    }

    private let dbQueue: DatabaseQueue

    init(location: Location = .memory) throws {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode=WAL")
        }
        switch location {
        case .memory:
            dbQueue = try DatabaseQueue(configuration: config)
        case .file(let url):
            dbQueue = try DatabaseQueue(path: url.path, configuration: config)
        }
        try DatabaseMigrations.migrator.migrate(dbQueue)
    }

    func upsert(_ record: SessionRecord) throws {
        try dbQueue.write { db in
            try record.save(db)
        }
    }

    func upsert(_ records: [SessionRecord]) throws {
        try dbQueue.write { db in
            for record in records {
                try record.save(db)
            }
        }
    }

    func fetchSessions() throws -> [SessionRecord] {
        try dbQueue.read { db in
            try SessionRecord.fetchAll(db)
        }
    }

    func deleteAll() throws {
        _ = try dbQueue.write { db in
            try SessionRecord.deleteAll(db)
        }
    }
}
