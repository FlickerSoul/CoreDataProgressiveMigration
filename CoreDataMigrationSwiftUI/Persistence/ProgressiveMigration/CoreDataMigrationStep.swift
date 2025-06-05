//
//  CoreDataMigrationStep.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//
import CoreData
import Foundation

struct CoreDataMigrationStep {
    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel

    // MARK: Init

    init(
        sourceVersion: CoreDataMigrationVersion,
        destinationVersion: CoreDataMigrationVersion
    ) throws(CoreDataMigrationError) {
        let sourceModel = try NSManagedObjectModel.managedObjectModel(forVersion: sourceVersion)
        let destinationModel = try NSManagedObjectModel.managedObjectModel(forVersion: destinationVersion)

        guard let mappingModel = CoreDataMigrationStep.mappingModel(
            fromSourceModel: sourceModel,
            toDestinationModel: destinationModel
        ) else {
            NSLog("Expected model mapping from \(sourceVersion.rawValue) to \(destinationVersion.rawValue) not present")
            throw .missingMigrationMapping(source: sourceVersion, destination: destinationVersion)
        }

        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }
}

extension CoreDataMigrationStep {
    private static func mappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        guard let customMapping = customMappingModel(
            fromSourceModel: sourceModel,
            toDestinationModel: destinationModel
        ) else {
            return inferredMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel)
        }

        return customMapping
    }

    private static func inferredMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    private static func customMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
