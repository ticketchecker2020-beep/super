import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ListDetailViewModel()
    @State private var newItemName = ""
    @State private var editingItem: GroceryItem?
    @State private var editedItemName = ""

    let list: ShoppingList

    private var sortedItems: [GroceryItem] {
        list.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section("Items") {
                ForEach(sortedItems) { item in
                    HStack(spacing: 12) {
                        Button {
                            viewModel.toggle(item, in: modelContext)
                        } label: {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(item.isChecked ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(item.name)
                            .font(.body)
                            .strikethrough(item.isChecked)

                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteItem(item, in: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editingItem = item
                            editedItemName = item.name
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }

            Section("Add Item") {
                TextField("New item", text: $newItemName)
                    .textInputAutocapitalization(.words)
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
        .alert("Edit Item", isPresented: editBinding) {
            TextField("Item name", text: $editedItemName)
            Button("Cancel", role: .cancel) {
                editingItem = nil
                editedItemName = ""
            }
            Button("Save") {
                if let item = editingItem {
                    viewModel.renameItem(item, to: editedItemName, in: modelContext)
                }
                editingItem = nil
                editedItemName = ""
            }
            .disabled(editedItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var editBinding: Binding<Bool> {
        Binding(
            get: { editingItem != nil },
            set: { isPresented in
                if !isPresented {
                    editingItem = nil
                    editedItemName = ""
                }
            }
        )
    }
}
