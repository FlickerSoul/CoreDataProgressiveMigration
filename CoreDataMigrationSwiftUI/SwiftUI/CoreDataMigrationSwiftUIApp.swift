//
//  CoreDataMigrationSwiftUIApp.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import SwiftUI

@main
struct CoreDataMigrationSwiftUIApp: App {
    let persistenceController = PersistenceController.shared

    @State var isPersistentStoreMigrationSuccessful: Bool?

    var body: some Scene {
        WindowGroup {
            rootContent
                .colorScheme(.light)
                .task {
                    do {
                        try await persistenceController.setup()
                        isPersistentStoreMigrationSuccessful = true
                        NSLog("Database initialized successfully")
                    } catch {
                        isPersistentStoreMigrationSuccessful = false
                        NSLog("Failed to initialize database: \(error)")
                    }
                }
        }
    }

    @ViewBuilder
    var rootContent: some View {
        if let isPersistentStoreMigrationSuccessful {
            if isPersistentStoreMigrationSuccessful {
                contentView
            } else {
                errorScreen
            }
        } else {
            Image(.icon)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 48))
                .frame(width: 200, height: 200)
        }
    }

    @ViewBuilder
    var contentView: some View {
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }

    @ViewBuilder
    var errorScreen: some View {
        ContentUnavailableView(
            "Cannot Initialize Database",
            systemImage: "swiftdata",
            description: Text("There was an error initializing the database. Please try again later.")
        )
    }
}
