//
//  CoreDataMigrator.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData
import Foundation

extension NSManagedObjectModel {
    // MARK: - Get Object Model By Version

    static func managedObjectModel(forVersion version: CoreDataMigrationVersion) throws(CoreDataMigrationError)
        -> NSManagedObjectModel {
        let mainBundle = Bundle.main
        let subdirectory = "CoreDataMigrationSwiftUI.momd"
        let modelName = version.rawValue

        let omoURL = mainBundle.url(forResource: modelName, withExtension: "omo", subdirectory: subdirectory)
        let momURL = mainBundle.url(forResource: modelName, withExtension: "mom", subdirectory: subdirectory)

        guard let url = omoURL ?? momURL else {
            NSLog("unable to find model in bundle of name \(modelName) in \(subdirectory) in \(Bundle.main.bundlePath)")
            throw .failToFindModelDefinition
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            NSLog("unable to load model in bundle of name \(modelName) at URL \(url)")
            throw .failToLoadModelDefinition
        }

        return model
    }

    static func compatibleModelForStoreMetadata(_ metadata: [String: Any]) -> NSManagedObjectModel? {
        let mainBundle = Bundle.main
        return NSManagedObjectModel.mergedModel(from: [mainBundle], forStoreMetadata: metadata)
    }
}

final class CoreDataMigrator: CoreDataMigratorProtocol {
    // MARK: - Check

    func requiresMigration(
        at storeURL: URL,
        toVersion version: CoreDataMigrationVersion
    ) throws(CoreDataMigrationError) -> Bool {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }

        return try CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) != version
    }

    // MARK: - Migration

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion) throws(CoreDataMigrationError) {
        try forceWALCheckpointingForStore(at: storeURL)

        var currentURL = storeURL
        let migrationSteps = try migrationStepsForStore(at: storeURL, toVersion: version)

        for migrationStep in migrationSteps {
            let manager = NSMigrationManager(
                sourceModel: migrationStep.sourceModel,
                destinationModel: migrationStep.destinationModel
            )
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(UUID().uuidString)

            do {
                try manager.migrateStore(
                    from: currentURL,
                    sourceType: NSSQLiteStoreType,
                    options: nil,
                    with: migrationStep.mappingModel,
                    toDestinationURL: destinationURL,
                    destinationType: NSSQLiteStoreType,
                    destinationOptions: nil
                )
            } catch {
                NSLog(
                    "failed attempting to migrate from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error)"
                )

                throw .failToMigrate(
                    source: migrationStep.sourceModel,
                    destination: migrationStep.destinationModel,
                    error: error
                )
            }

            if currentURL != storeURL {
                // Destroy intermediate step's store
                try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }

            currentURL = destinationURL
        }

        try NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)

        if currentURL != storeURL {
            try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }

    private func migrationStepsForStore(
        at storeURL: URL,
        toVersion destinationVersion: CoreDataMigrationVersion
    ) throws(CoreDataMigrationError) -> [CoreDataMigrationStep] {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            NSLog("Unknown metadata")
            throw .unknownStoreMetadata
        }

        guard let sourceVersion = try CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) else {
            NSLog("unknown store version at URL \(storeURL)")
            throw .unknownStoreVersion
        }

        return try migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
    }

    private func migrationSteps(
        fromSourceVersion sourceVersion: CoreDataMigrationVersion,
        toDestinationVersion destinationVersion: CoreDataMigrationVersion
    ) throws(CoreDataMigrationError) -> [CoreDataMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
            let migrationStep = try CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
            migrationSteps.append(migrationStep)

            sourceVersion = nextVersion
        }

        return migrationSteps
    }

    // MARK: - WAL

    func forceWALCheckpointingForStore(at storeURL: URL) throws(CoreDataMigrationError) {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL),
              let currentModel = NSManagedObjectModel.compatibleModelForStoreMetadata(metadata) else {
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch {
            NSLog("failed to force WAL checkpointing, error: \(error)")
            throw .failToMigrateWAL(underlying: error)
        }
    }
}

private extension NSPersistentStoreCoordinator {
    // MARK: - Destroy

    static func destroyStore(at storeURL: URL) throws(CoreDataMigrationError) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } catch {
            NSLog("failed to destroy persistent store at \(storeURL), error: \(error)")
            throw .failToDestroyStore(at: storeURL, underlying: error)
        }
    }

    // MARK: - Replace

    static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws(CoreDataMigrationError) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(
                at: targetURL,
                destinationOptions: nil,
                withPersistentStoreFrom: sourceURL,
                sourceOptions: nil,
                ofType: NSSQLiteStoreType
            )
        } catch {
            NSLog("failed to replace persistent store at \(targetURL) with \(sourceURL), error: \(error)")
            throw .failToReplaceOldStore(at: targetURL, withNewStoreAt: sourceURL, underlying: error)
        }
    }

    // MARK: - Meta

    static func metadata(at storeURL: URL) -> [String: Any]? {
        try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        )
    }

    // MARK: - Add

    func addPersistentStore(
        at storeURL: URL,
        options: [AnyHashable: Any]
    ) throws(CoreDataMigrationError) -> NSPersistentStore {
        do {
            return try addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options
            )
        } catch {
            NSLog("failed to add persistent store to coordinator at \(storeURL), options: \(options), error: \(error)")
            throw .failToAddStoreToCoordinator(at: storeURL, underlying: error)
        }
    }
}

private extension CoreDataMigrationVersion {
    static func compatibleVersionForStoreMetadata(_ metadata: [String: Any]) throws(CoreDataMigrationError)
        -> CoreDataMigrationVersion? {
        do {
            let compatibleVersion = try CoreDataMigrationVersion.allCases
                .first { version throws(CoreDataMigrationError) -> Bool in
                    let model = try NSManagedObjectModel.managedObjectModel(forVersion: version)
                    return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
                }

            return compatibleVersion
        } catch {
            NSLog("failed to determine compatible version for store metadata: \(error)")
            throw error as! CoreDataMigrationError
        }
    }
}
