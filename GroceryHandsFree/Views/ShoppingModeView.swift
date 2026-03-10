import SwiftUI
import SwiftData

struct ShoppingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listViewModel = ListDetailViewModel()
    @StateObject private var shoppingModeViewModel = ShoppingModeViewModel()

    let list: ShoppingList

    var body: some View {
        VStack(spacing: 20) {
            if let current = shoppingModeViewModel.visibleQueue.first {
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

            Text(shoppingModeViewModel.lastRecognizedActionText)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("Queue")
                    .font(.headline)

                ForEach(shoppingModeViewModel.visibleQueue) { item in
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
                    shoppingModeViewModel.perform(.repeatQueue, with: list)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(shoppingModeViewModel.visibleQueue.isEmpty ? "Done" : "Next / Mark Done") {
                    advanceToNextItem()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(shoppingModeViewModel.visibleQueue.isEmpty)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .navigationTitle("Shopping Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            shoppingModeViewModel.startGuidedFlow(with: list)
        }
        .onDisappear {
            shoppingModeViewModel.stopSpeech()
        }
    }

    private func advanceToNextItem() {
        print("[ShoppingMode] Next/Mark Done tapped")
        shoppingModeViewModel.perform(.markDone, with: list) { item in
            listViewModel.toggle(item, in: modelContext)
        }
        shoppingModeViewModel.perform(.advance, with: list)
        shoppingModeViewModel.perform(.readNextThree, with: list)
    }
}
