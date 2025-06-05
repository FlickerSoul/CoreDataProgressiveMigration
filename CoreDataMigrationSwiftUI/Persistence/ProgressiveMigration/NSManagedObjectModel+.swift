//
//  NSManagedObjectModel+.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/5/25.
//
import CoreData

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
}
