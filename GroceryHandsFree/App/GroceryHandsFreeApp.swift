import SwiftUI
import SwiftData

@main
struct GroceryHandsFreeApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                ShoppingList.self,
                GroceryItem.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try MockDataService.seedIfNeeded(in: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ShoppingListsView()
        }
        .modelContainer(modelContainer)
    }
}
