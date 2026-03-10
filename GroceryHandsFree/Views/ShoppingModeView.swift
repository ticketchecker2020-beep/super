import SwiftUI
import SwiftData

struct ShoppingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listViewModel = ListDetailViewModel()
    @StateObject private var shoppingModeViewModel = ShoppingModeViewModel()
    @State private var feedbackMessage = ""

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
        ScrollView {
            VStack(spacing: 20) {
                if let current = spokenQueue.first {
                    VStack(spacing: 12) {
                        Text("Current")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(current.name)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.75)

                        Text("Qty: \(current.quantity)")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                        Text("All items collected!")
                            .font(.title2.bold())
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Queue")
                        .font(.headline)

                    ForEach(spokenQueue) { item in
                        HStack(spacing: 10) {
                            Image(systemName: shoppingModeViewModel.currentlySpokenItemID == item.id ? "speaker.wave.2.fill" : "circle.fill")
                                .foregroundStyle(shoppingModeViewModel.currentlySpokenItemID == item.id ? .blue : .secondary)
                            Text("\(item.name) x\(item.quantity)")
                                .font(.title3)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            shoppingModeViewModel.currentlySpokenItemID == item.id
                                ? Color.blue.opacity(0.18)
                                : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                }

                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 12) {
                    Button("Repeat") {
                        print("[ShoppingMode] Repeat tapped")
                        shoppingModeViewModel.repeatQueue(spokenQueue)
                        showFeedback("Repeating current queue")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 52)

                    Button(spokenQueue.isEmpty ? "Done" : "Next / Mark Done") {
                        advanceToNextItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .disabled(spokenQueue.isEmpty)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "enter")
        }
        .onDisappear {
            shoppingModeViewModel.stopSpeech()
        }
    }

    private func advanceToNextItem() {
        guard let current = spokenQueue.first else { return }

        print("[ShoppingMode] Advance tapped for item: \(current.name)")
        listViewModel.toggle(current, in: modelContext)
        showFeedback("Marked \(current.name) done")

        DispatchQueue.main.async {
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "advance")
        }
    }

    private func showFeedback(_ message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                feedbackMessage = ""
            }
        }
    }
}
