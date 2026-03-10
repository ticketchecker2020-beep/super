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

                Button(spokenQueue.isEmpty ? "Done" : "Next / Mark Done") {
                    advanceToNextItem()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(spokenQueue.isEmpty)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text("Debug")
                    .font(.headline)

                Text(debugQueueSnapshot)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("Read Next 3") {
                        shoppingModeViewModel.readNextThree(remainingItems)
                    }
                    .buttonStyle(.bordered)

                    Button("Log Queue") {
                        shoppingModeViewModel.logQueueState(remainingItems, source: "manual")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 8) {
                    TextField("Remote cmd: repeat | next | done | read3 | queue", text: $shoppingModeViewModel.remoteCommandInput)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Send") {
                        shoppingModeViewModel.handleRemoteInput(
                            shoppingModeViewModel.remoteCommandInput,
                            items: remainingItems,
                            onMarkDone: markCurrentItemDone,
                            onAdvance: advanceToNextItem
                        )
                        shoppingModeViewModel.remoteCommandInput = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("[ShoppingMode] entering_shopping_mode list='\(list.name)'")
            shoppingModeViewModel.logQueueState(remainingItems, source: "enter")
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "enter")
        }
        .onDisappear {
            shoppingModeViewModel.stopSpeech()
        }
    }

    private var debugQueueSnapshot: String {
        let items = remainingItems.prefix(5).enumerated().map { index, item in
            "\(index + 1). \(item.name) x\(item.quantity)"
        }

        if items.isEmpty {
            return "Queue: <empty>"
        }

        return "Queue:\n" + items.joined(separator: "\n")
    }

    private func advanceToNextItem() {
        guard let current = spokenQueue.first else { return }

        print("[ShoppingMode] mark_done item='\(current.name)'")
        print("[ShoppingMode] advance item='\(current.name)'")
        listViewModel.toggle(current, in: modelContext)

        DispatchQueue.main.async {
            shoppingModeViewModel.logQueueState(remainingItems, source: "after_advance")
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "advance")
        }
    }

    private func markCurrentItemDone() {
        guard let current = spokenQueue.first else { return }
        print("[ShoppingMode] mark_done item='\(current.name)'")
        listViewModel.toggle(current, in: modelContext)

        DispatchQueue.main.async {
            shoppingModeViewModel.logQueueState(remainingItems, source: "after_mark_done")
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "advance")
        }
    }
}
