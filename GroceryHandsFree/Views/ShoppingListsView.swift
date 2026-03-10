import SwiftUI
import SwiftData

struct ShoppingListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingList.createdAt, order: .reverse) private var lists: [ShoppingList]
    @StateObject private var viewModel = ShoppingListsViewModel()
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Your Lists") {
                    ForEach(lists) { list in
                        NavigationLink(value: list) {
                            HStack {
                                Text(list.name)
                                Spacer()
                                Text("\(list.items.count) items")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Create List") {
                    TextField("New list name", text: $newListName)
                    Button("Add List") {
                        viewModel.addList(named: newListName, in: modelContext)
                        newListName = ""
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Shopping Lists")
            .navigationDestination(for: ShoppingList.self) { list in
                ListDetailView(list: list)
            }
        }
    }
}

#Preview {
    ShoppingListsView()
}
