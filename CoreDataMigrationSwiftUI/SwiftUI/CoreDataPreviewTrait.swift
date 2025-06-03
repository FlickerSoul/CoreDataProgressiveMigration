//
//  CoreDataPreviewTrait.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//
import SwiftUI

struct CoreDataPreviewContentConfig {
    let count: Int
}

private struct CoreDataPreviewTraitModifier: PreviewModifier {
    typealias Context = PersistenceController

    let previewContentConfig: CoreDataPreviewContentConfig

    @State private var isCoreDataInitializedSuccessfully: Bool?

    static func makeSharedContext() async throws -> Context {
        PersistenceController.preview
    }

    func body(content: Content, context: Context) -> some View {
        rootContent(content: content, coreDataController: context)
            .task {
                do {
                    try await context.setup(inMemory: true)
                    setupPreviewContent(in: context)
                    isCoreDataInitializedSuccessfully = true
                    print("Core Data initialized successfully")
                } catch {
                    isCoreDataInitializedSuccessfully = false
                    print("Failed to initialize Core Data: \(error)")
                }
            }
    }

    func setupPreviewContent(in coreDataController: Context) {
        let viewContext = coreDataController.container.viewContext
        for index in 0 ..< previewContentConfig.count {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.name = "Preview Item \(index)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this
            // function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            print("Cannot save preview content")
            fatalError("Unresolved error in save model context: \(nsError), \(nsError.userInfo)")
        }
    }

    @ViewBuilder
    func rootContent(content: Content, coreDataController: Context) -> some View {
        if let isCoreDataInitializedSuccessfully {
            if isCoreDataInitializedSuccessfully {
                content
                    .environment(\.managedObjectContext, coreDataController.container.viewContext)
            } else {
                Text("Failed to initialize Core Data")
            }
        } else {
            Text("Initializing Core Data...")
        }
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static func previewCoreDataContext(contentConfig: CoreDataPreviewContentConfig = .init(count: 10)) -> Self {
        .modifier(CoreDataPreviewTraitModifier(previewContentConfig: contentConfig))
    }
}
