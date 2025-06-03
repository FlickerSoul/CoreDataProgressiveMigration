//
//  ContentView.swift
//  CoreDataMigrationSwiftUI
//
//  Created by Larry Zeng on 6/3/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest
    private var items: FetchedResults<Item>

    @State private var showNameEditAlert = false
    @State private var newItemName = ""

    init() {
        let nsFetchRequest = NSFetchRequest<Item>(entityName: "Item")
        nsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
        _items = .init(fetchRequest: nsFetchRequest, animation: .default)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack {
                            Text("Item name: \(item.name!)")
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name!)
                            Text(item.timestamp!, formatter: itemFormatter)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        showNameEditAlert = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .alert("Add Item", isPresented: $showNameEditAlert) {
                TextField("Item Name", text: $newItemName)
                Button {
                    addItem()
                } label: {
                    Text("Add")
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).count == 0)
            }

            Text("Select an item")
        }
    }

    private func addItem() {
        let itemName = newItemName
        newItemName = ""

        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.name = itemName

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this
                // function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this
                // function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview(traits: .previewCoreDataContext()) {
    ContentView()
}
