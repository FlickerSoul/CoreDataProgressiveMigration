//
//  Persistence.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData

struct PersistenceController {
    enum PersistenceError: Error {
        case failToLoadPersistentStore(underlying: Error)
        case failToMigrateStore(underlying: CoreDataMigrationError)
    }

    static let shared = PersistenceController()

    let migrator: CoreDataMigratorProtocol

    @MainActor
    static let preview: PersistenceController = .init(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false, migrator: CoreDataMigratorProtocol = CoreDataMigrator()) {
        container = NSPersistentContainer(name: "CoreDataMigrationSwiftUI")
        let storeDescription = container.persistentStoreDescriptions.first!

        storeDescription.shouldInferMappingModelAutomatically = false
        storeDescription.shouldMigrateStoreAutomatically = false
        storeDescription.type = NSSQLiteStoreType

        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        self.migrator = migrator
    }

    func setup(inMemory: Bool = false) async throws(PersistenceError) {
        do {
            if !inMemory {
                try migrateStoreIfNeeded()
            }

            return try await withCheckedThrowingContinuation { continuation in
                container.loadPersistentStores { storeDescription, error in
                    if let error = error as NSError? {
                        NSLog("Unresolved error during persistent store loading: \(error), \(error.userInfo)")
                        continuation.resume(throwing: PersistenceError.failToLoadPersistentStore(underlying: error))
                    }

                    NSLog("Persistent store loaded successfully: \(storeDescription)")
                    continuation.resume(returning: ())
                }
            }
        } catch let error as PersistenceError {
            NSLog("Failed to set up persistent container: \(error)")
            throw error
        } catch let error as CoreDataMigrationError {
            NSLog("Core Data migration failed: \(error)")
            throw PersistenceError.failToMigrateStore(underlying: error)
        } catch {
            NSLog("Unexpected error during persistent container setup: \(error)")
            fatalError("This shouldn't happen")
        }
    }

    private func migrateStoreIfNeeded() throws(CoreDataMigrationError) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            NSLog("persistentContainer was not set up properly, missing store URL")
            throw CoreDataMigrationError.containerMisconfigured
        }

        if try migrator.requiresMigration(at: storeURL, toVersion: CoreDataMigrationVersion.current) {
            try migrator.migrateStore(at: storeURL, toVersion: CoreDataMigrationVersion.current)
        }
    }
}
