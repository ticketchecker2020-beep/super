import Foundation
import SwiftData

@MainActor
final class ShoppingListsViewModel: ObservableObject {
    func addList(named name: String, in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let list = ShoppingList(name: trimmed)
        context.insert(list)
        try? context.save()
    }
}
