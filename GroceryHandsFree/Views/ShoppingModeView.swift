import SwiftUI
import SwiftData

struct ShoppingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listViewModel = ListDetailViewModel()
    @StateObject private var shoppingModeViewModel = ShoppingModeViewModel()
    @State private var feedbackText = "Ready"

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

            gestureControl

            Text(feedbackText)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)

            Text("Single tap: Done + Next • Double tap: Repeat • Long press: Next 3")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("[ShoppingMode] Entered shopping mode for list: \(list.name)")
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "enter")
            feedbackText = "Reading current + next 2 items"
        }
        .onDisappear {
            shoppingModeViewModel.stopSpeech()
        }
    }

    private var gestureControl: some View {
        let tapGesture = TapGesture(count: 2)
            .exclusively(before: TapGesture(count: 1))
            .onEnded { value in
                switch value {
                case .first:
                    handleControlAction(.doubleTapRepeat)
                case .second:
                    handleControlAction(.singleTapAdvance)
                }
            }

        let longPress = LongPressGesture(minimumDuration: 0.7)
            .onEnded { _ in
                handleControlAction(.longPressPreview)
            }

        return RoundedRectangle(cornerRadius: 18)
            .fill(Color.accentColor.opacity(0.16))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.largeTitle)
                    Text("Shopping Control")
                        .font(.title3.bold())
                    Text(spokenQueue.isEmpty ? "No items remaining" : "Tap gestures enabled")
                        .font(.headline)
                }
                .foregroundStyle(.primary)
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .contentShape(Rectangle())
            .gesture(longPress)
            .highPriorityGesture(tapGesture)
            .accessibilityLabel("Shopping control")
            .accessibilityHint("Single tap marks done, double tap repeats instruction, long press reads next three")
    }

    private func handleControlAction(_ action: ShoppingModeViewModel.ShoppingControlAction) {
        guard !spokenQueue.isEmpty else {
            feedbackText = "No items left"
            print("[ShoppingMode] Ignored action \(action.rawValue) because queue is empty")
            return
        }

        shoppingModeViewModel.handle(action: action, queue: spokenQueue) {
            advanceToNextItem()
        }

        feedbackText = shoppingModeViewModel.latestActionDescription
        print("[ShoppingMode] Feedback updated: \(feedbackText)")
    }

    private func advanceToNextItem() {
        guard let current = spokenQueue.first else { return }

        print("[ShoppingMode] Advance tapped for item: \(current.name)")
        listViewModel.toggle(current, in: modelContext)
        feedbackText = "Completed \(current.name), moving to next"
        print("[ShoppingMode] State transition -> completed current item, refreshing queue")

        DispatchQueue.main.async {
            shoppingModeViewModel.startGuidedFlow(with: spokenQueue, reason: "advance")
        }
    }
}
