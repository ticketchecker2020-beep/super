import Foundation
import SwiftData

@MainActor
final class ListDetailViewModel: ObservableObject {
    func addItem(named name: String, to list: ShoppingList, in context: ModelContext) {
        let sanitized = sanitizeInput(name)
        guard !sanitized.isEmpty else { return }

        let nextOrder = (list.items.map(\.sortOrder).max() ?? -1) + 1
        let item = GroceryItem(name: sanitized, sortOrder: nextOrder, list: list)
        list.items.append(item)
        context.insert(item)
        save(context)
        print("[DEBUG] Added item '\(sanitized)' to list '\(list.name)'")
    }

    func renameItem(_ item: GroceryItem, to newName: String, in context: ModelContext) {
        let sanitized = sanitizeInput(newName)
        guard !sanitized.isEmpty else { return }

        let oldName = item.name
        item.name = sanitized
        save(context)
        print("[DEBUG] Renamed item from '\(oldName)' to '\(sanitized)'")
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

    private func sanitizeInput(_ value: String) -> String {
        let noControls = value.unicodeScalars.filter { !$0.properties.isControl }
        let flattened = String(String.UnicodeScalarView(noControls))
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return String(flattened.prefix(80))
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[DEBUG] Failed to save list detail context: \(error)")
        }
    }
}
