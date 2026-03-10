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
        try? context.save()
    }

    func toggle(_ item: GroceryItem, in context: ModelContext) {
        item.isChecked.toggle()
        try? context.save()
    }
}
