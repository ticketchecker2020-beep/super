import SwiftUI
import SwiftData

struct ShoppingListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingList.createdAt, order: .reverse) private var lists: [ShoppingList]
    @StateObject private var viewModel = ShoppingListsViewModel()
    @State private var newListName = ""
    @State private var renamingList: ShoppingList?
    @State private var renameListName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Your Lists") {
                    ForEach(lists) { list in
                        NavigationLink(value: list) {
                            HStack {
                                Text(list.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(list.items.count) items")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 6)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteList(list, in: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                renamingList = list
                                renameListName = list.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }

                Section("Create List") {
                    TextField("New list name", text: $newListName)
                        .textInputAutocapitalization(.words)

                    Button("Add List") {
                        viewModel.addList(named: newListName, in: modelContext)
                        newListName = ""
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Shopping Lists")
            .navigationDestination(for: ShoppingList.self) { list in
                ListDetailView(list: list)
            }
            .alert("Rename List", isPresented: renameBinding) {
                TextField("List name", text: $renameListName)
                Button("Cancel", role: .cancel) {
                    renamingList = nil
                    renameListName = ""
                }
                Button("Save") {
                    if let list = renamingList {
                        viewModel.renameList(list, to: renameListName, in: modelContext)
                    }
                    renamingList = nil
                    renameListName = ""
                }
                .disabled(renameListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renamingList != nil },
            set: { isPresented in
                if !isPresented {
                    renamingList = nil
                    renameListName = ""
                }
            }
        )
    }
}

#Preview {
    ShoppingListsView()
}
