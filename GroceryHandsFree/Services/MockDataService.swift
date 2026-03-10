import Foundation
import SwiftData

enum MockDataService {
    static func seedIfNeeded(in context: ModelContext) throws {
        var descriptor = FetchDescriptor<ShoppingList>()
        descriptor.fetchLimit = 1

        if try context.fetch(descriptor).isEmpty {
            let weekly = ShoppingList(name: "Weekly Essentials")
            let produce = ShoppingList(name: "Weekend Produce Run")

            let weeklyItems = [
                GroceryItem(name: "Milk", quantity: 1, sortOrder: 0, list: weekly),
                GroceryItem(name: "Eggs", quantity: 1, sortOrder: 1, list: weekly),
                GroceryItem(name: "Bread", quantity: 2, sortOrder: 2, list: weekly),
                GroceryItem(name: "Chicken Breast", quantity: 1, sortOrder: 3, list: weekly)
            ]

            let produceItems = [
                GroceryItem(name: "Bananas", quantity: 6, sortOrder: 0, list: produce),
                GroceryItem(name: "Spinach", quantity: 1, sortOrder: 1, list: produce),
                GroceryItem(name: "Tomatoes", quantity: 4, sortOrder: 2, list: produce)
            ]

            weekly.items = weeklyItems
            produce.items = produceItems

            context.insert(weekly)
            context.insert(produce)
            try context.save()
        }
    }
}
