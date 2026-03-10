import Foundation
import SwiftData

@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var isChecked: Bool
    var sortOrder: Int
    var list: ShoppingList?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        isChecked: Bool = false,
        sortOrder: Int = 0,
        list: ShoppingList? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
        self.sortOrder = sortOrder
        self.list = list
    }
}
