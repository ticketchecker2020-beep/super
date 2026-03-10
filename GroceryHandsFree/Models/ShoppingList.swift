import Foundation
import SwiftData

@Model
final class ShoppingList {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.list)
    var items: [GroceryItem]

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, items: [GroceryItem] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}
