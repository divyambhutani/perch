import Foundation
import GRDB

enum DatabaseMigrations {
    static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createSessionRecord") { db in
            try db.create(table: "sessionRecord") { table in
                table.column("id", .text).notNull().primaryKey()
                table.column("title", .text).notNull()
                table.column("state", .text).notNull()
                table.column("updatedAt", .datetime).notNull()
            }
        }
        return migrator
    }()
}
