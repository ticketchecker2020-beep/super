import SwiftUI
import SwiftData

struct ShoppingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ListDetailViewModel()

    let list: ShoppingList

    private var remainingItems: [GroceryItem] {
        list.items
            .filter { !$0.isChecked }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(spacing: 20) {
            if let current = remainingItems.first {
                Text("Next Item")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(current.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Qty: \(current.quantity)")
                    .font(.title3)

                Button("Mark as Collected") {
                    viewModel.toggle(current, in: modelContext)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                Text("All items collected!")
                    .font(.title2.bold())
            }

            List {
                Section("Progress") {
                    ForEach(list.items.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        Label(
                            "\(item.name) x\(item.quantity)",
                            systemImage: item.isChecked ? "checkmark.circle.fill" : "circle"
                        )
                        .foregroundStyle(item.isChecked ? .green : .primary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
