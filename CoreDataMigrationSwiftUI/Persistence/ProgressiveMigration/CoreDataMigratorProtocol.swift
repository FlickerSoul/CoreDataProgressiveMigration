//
//  CoreDataMigratorProtocol.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData

protocol CoreDataMigratorProtocol: Sendable {
    func requiresMigration(
        at storeURL: URL,
        toVersion version: CoreDataMigrationVersion
    ) throws(CoreDataMigrationError) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion) throws(CoreDataMigrationError)
}
