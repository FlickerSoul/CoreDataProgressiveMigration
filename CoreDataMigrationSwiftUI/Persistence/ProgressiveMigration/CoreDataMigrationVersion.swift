//
//  CoreDataMigrationVersion.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData

enum CoreDataMigrationVersion: String, CaseIterable {
    case v1 = "V1"
    case v2 = "V2-add-name"

    // MARK: - Current

    static var current: CoreDataMigrationVersion {
        guard let current = allCases.last else {
            fatalError("no model versions found")
        }

        return current
    }

    // MARK: - Migration

    func nextVersion() -> CoreDataMigrationVersion? {
        switch self {
        case .v1: .v2
        case .v2: nil
        }
    }
}
