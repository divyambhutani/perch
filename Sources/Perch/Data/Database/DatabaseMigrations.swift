import Foundation
import GRDB

enum DatabaseMigrations {
    static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_sessions") { db in
            try db.create(table: "sessions") { table in
                table.primaryKey("id", .text)
                table.column("project", .text)
                table.column("cwd", .text)
                table.column("startedAt", .datetime)
                table.column("lastActivity", .datetime)
                table.column("state", .text).notNull().defaults(to: "idle")
                table.column("contextPct", .double).notNull().defaults(to: 0)
                table.column("tokenTotal", .integer).notNull().defaults(to: 0)
            }
        }
        return migrator
    }()
}
