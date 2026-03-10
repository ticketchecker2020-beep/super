import Foundation
import SwiftData

@MainActor
final class ShoppingListsViewModel: ObservableObject {
    func addList(named name: String, in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let list = ShoppingList(name: trimmed)
        context.insert(list)
        save(context)
        print("[DEBUG] Created shopping list: \(trimmed)")
    }

    func renameList(_ list: ShoppingList, to newName: String, in context: ModelContext) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let oldName = list.name
        list.name = trimmed
        save(context)
        print("[DEBUG] Renamed shopping list from '\(oldName)' to '\(trimmed)'")
    }

    func deleteList(_ list: ShoppingList, in context: ModelContext) {
        let name = list.name
        context.delete(list)
        save(context)
        print("[DEBUG] Deleted shopping list: \(name)")
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[DEBUG] Failed to save shopping lists context: \(error)")
        }
    }
}
