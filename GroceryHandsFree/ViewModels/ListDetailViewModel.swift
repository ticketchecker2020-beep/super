import Foundation
import SwiftData

@MainActor
final class ListDetailViewModel: ObservableObject {
    func addItem(named name: String, to list: ShoppingList, in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let nextOrder = (list.items.map(\.sortOrder).max() ?? -1) + 1
        let item = GroceryItem(name: trimmed, sortOrder: nextOrder, list: list)
        list.items.append(item)
        context.insert(item)
        save(context)
        print("[DEBUG] Added item '\(trimmed)' to list '\(list.name)'")
    }

    func renameItem(_ item: GroceryItem, to newName: String, in context: ModelContext) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let oldName = item.name
        item.name = trimmed
        save(context)
        print("[DEBUG] Renamed item from '\(oldName)' to '\(trimmed)'")
    }

    func deleteItem(_ item: GroceryItem, in context: ModelContext) {
        let name = item.name
        if let list = item.list {
            list.items.removeAll { $0.id == item.id }
        }

        context.delete(item)
        save(context)
        print("[DEBUG] Deleted item: \(name)")
    }

    func toggle(_ item: GroceryItem, in context: ModelContext) {
        item.isChecked.toggle()
        save(context)
        print("[DEBUG] Toggled item '\(item.name)' completion to \(item.isChecked)")
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[DEBUG] Failed to save list detail context: \(error)")
        }
    }
}
