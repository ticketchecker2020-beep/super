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
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(list.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                Spacer(minLength: 8)
                                Text("\(list.items.count) items")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 10)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                print("[Lists] Delete list tapped: \(list.name)")
                                viewModel.deleteList(list, in: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                print("[Lists] Rename list tapped: \(list.name)")
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
                    VStack(spacing: 12) {
                        TextField("New list name", text: $newListName)
                            .textInputAutocapitalization(.words)
                            .textFieldStyle(.roundedBorder)

                        Button("Add List") {
                            print("[Lists] Add list tapped")
                            viewModel.addList(named: newListName, in: modelContext)
                            newListName = ""
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listSectionSpacing(18)
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
                        print("[Lists] Rename list saved: \(list.name)")
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
