//
//  TestProgressiveMigration.swift
//  CoreDataMigrationSwiftUITests
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData
@testable import CoreDataMigrationSwiftUI
import Testing

@Suite("Test Progressive Migration")
struct TestProgressiveMigration {
    let migrator: CoreDataMigrator = .init()
    let tempFileTearDown = TempFileManager()

    @Test("Migrate", arguments: [
        (
            "Migrate from V1 to V2",
            "V1.sqlite",
            CoreDataMigrationVersion.v2,
            Self.migrate_V1_to_V2
        ),
    ])
    func migrate(
        name _: String,
        sourceFileName: String,
        targetVersion: CoreDataMigrationVersion,
        dataTest: (NSManagedObjectContext) async throws -> Void
    ) async throws {
        let sourceURL = try TempFileManager.moveFileFromBundleToTempDirectory(
            filename: sourceFileName,
            subdir: "ProgressiveMigration"
        )

        #expect(throws: Never.self) {
            try migrator.migrateStore(at: sourceURL, toVersion: targetVersion)
        }

        #expect(FileManager.default.fileExists(atPath: sourceURL.path))

        let model = try NSManagedObjectModel.managedObjectModel(forVersion: targetVersion)
        let context = NSManagedObjectContext(model: model, storeURL: sourceURL)

        await #expect(throws: Never.self) {
            try await dataTest(context)
        }

        context.destroyStore()
    }

    static func migrate_V1_to_V2(_ context: NSManagedObjectContext) async throws {
        let itemFetchRequest = NSFetchRequest<Item>(entityName: "Item")
        let items = try context.fetch(itemFetchRequest)
        NSLog("Fetched \(items.count) messages")

        for item in items {
            #expect(item.name == "Unknown")
        }
    }
}

private extension NSManagedObjectContext {
    convenience init(model: NSManagedObjectModel, storeURL: URL) {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )

        self.init(concurrencyType: .mainQueueConcurrencyType)

        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    func destroyStore() {
        persistentStoreCoordinator?.persistentStores.forEach {
            try? persistentStoreCoordinator?.remove($0)
            try? persistentStoreCoordinator?.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)
        }
    }
}
