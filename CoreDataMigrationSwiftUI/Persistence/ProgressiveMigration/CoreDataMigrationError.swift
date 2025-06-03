//
//  CoreDataMigrationError.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//
@preconcurrency import CoreData

enum CoreDataMigrationError: Error {
    case missingMigrationMapping(source: CoreDataMigrationVersion, destination: CoreDataMigrationVersion)
    case containerMisconfigured
    case failToFindModelDefinition
    case failToLoadModelDefinition
    case failToMigrate(source: NSManagedObjectModel, destination: NSManagedObjectModel, error: any Error)
    case unknownStoreMetadata
    case unknownStoreVersion
    case failToMigrateWAL(underlying: any Error)
    case failToDestroyStore(at: URL, underlying: any Error)
    case failToReplaceOldStore(at: URL, withNewStoreAt: URL, underlying: any Error)
    case failToAddStoreToCoordinator(at: URL, underlying: any Error)
}
