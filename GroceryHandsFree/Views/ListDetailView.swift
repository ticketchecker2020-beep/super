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
                            print("[ListDetail] Toggle item tapped: \(item.name)")
                            viewModel.toggle(item, in: modelContext)
                        } label: {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(item.isChecked ? .green : .secondary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        Text(item.name)
                            .font(.body)
                            .strikethrough(item.isChecked)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            print("[ListDetail] Delete item tapped: \(item.name)")
                            viewModel.deleteItem(item, in: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            print("[ListDetail] Edit item tapped: \(item.name)")
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
                VStack(spacing: 12) {
                    TextField("New item", text: $newItemName)
                        .textInputAutocapitalization(.words)
                        .textFieldStyle(.roundedBorder)

                    Button("Add Item") {
                        print("[ListDetail] Add item tapped")
                        viewModel.addItem(named: newItemName, to: list, in: modelContext)
                        newItemName = ""
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink("Enter Shopping Mode") {
                    ShoppingModeView(list: list)
                }
                .font(.headline)
                .frame(minHeight: 44)
            }
        }
        .listSectionSpacing(18)
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
                    print("[ListDetail] Save edited item tapped: \(item.name)")
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
