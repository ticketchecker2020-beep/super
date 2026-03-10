import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ListDetailViewModel()
    @State private var newItemName = ""

    let list: ShoppingList

    private var sortedItems: [GroceryItem] {
        list.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section("Items") {
                ForEach(sortedItems) { item in
                    HStack {
                        Button {
                            viewModel.toggle(item, in: modelContext)
                        } label: {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isChecked ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text("\(item.name) x\(item.quantity)")
                            .strikethrough(item.isChecked)
                    }
                }
            }

            Section("Add Item") {
                TextField("New item", text: $newItemName)
                Button("Add Item") {
                    viewModel.addItem(named: newItemName, to: list, in: modelContext)
                    newItemName = ""
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section {
                NavigationLink("Enter Shopping Mode") {
                    ShoppingModeView(list: list)
                }
                .font(.headline)
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
