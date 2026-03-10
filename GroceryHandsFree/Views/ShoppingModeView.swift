import SwiftUI
import SwiftData

struct ShoppingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listViewModel = ListDetailViewModel()
    @StateObject private var shoppingModeViewModel = ShoppingModeViewModel()

    let list: ShoppingList

    private var remainingItems: [GroceryItem] {
        list.items
            .filter { !$0.isChecked }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var spokenQueue: [GroceryItem] {
        Array(remainingItems.prefix(3))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let current = spokenQueue.first {
                VStack(spacing: 10) {
                    Text("Current")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(current.name)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Qty: \(current.quantity)")
                        .font(.title3)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                Text("All items collected!")
                    .font(.title2.bold())
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Queue")
                    .font(.headline)

                ForEach(spokenQueue) { item in
                    HStack {
                        Image(systemName: shoppingModeViewModel.currentlySpokenItemID == item.id ? "speaker.wave.2.fill" : "circle.fill")
                            .foregroundStyle(shoppingModeViewModel.currentlySpokenItemID == item.id ? .blue : .secondary)
                        Text("\(item.name) x\(item.quantity)")
                            .font(.title3)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        shoppingModeViewModel.currentlySpokenItemID == item.id
                            ? Color.blue.opacity(0.16)
                            : Color.secondary.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }

            HStack(spacing: 12) {
                Button("Repeat") {
                    shoppingModeViewModel.repeatQueue(spokenQueue)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(spokenQueue.isEmpty)

                Button(spokenQueue.isEmpty ? "Done" : "Next") {
                    advanceToNextItem()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(spokenQueue.isEmpty)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "enter")
        }
        .onChange(of: remainingItems.map(\.id)) { _, _ in
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "queue-changed")
        }
        .onDisappear {
            shoppingModeViewModel.stopSpeech()
        }
    }

    private func advanceToNextItem() {
        guard let current = spokenQueue.first else {
            print("[ShoppingMode] Advance tapped with no remaining items")
            return
        }

        print("[ShoppingMode] Advance tapped for item: \(current.name)")
        listViewModel.toggle(current, in: modelContext)
    }
}
