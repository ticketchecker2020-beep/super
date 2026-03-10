import Foundation

@MainActor
final class ShoppingModeViewModel: ObservableObject {
    enum ShoppingAction: String {
        case repeatQueue = "Repeat"
        case markDone = "Mark done"
        case advance = "Advance"
        case readNextThree = "Read next 3"
    }

    @Published var currentlySpokenItemID: UUID?
    @Published var visibleQueue: [GroceryItem] = []
    @Published var lastRecognizedActionText = "Last action: —"

    private let speechService: SpeechService

    init(speechService: SpeechService = SpeechService()) {
        self.speechService = speechService
        self.speechService.onDidStartItem = { [weak self] itemID in
            self?.currentlySpokenItemID = itemID
        }
    }

    func startGuidedFlow(with list: ShoppingList) {
        refreshQueue(from: list)
        readNextThree(in: list, reason: "enter")
    }

    func repeat(in list: ShoppingList) {
        refreshQueue(from: list)
        speechService.speak(items: visibleQueue, reason: "repeat")
        updateStatus(.repeatQueue, detail: queueSummary())
        print("[ShoppingMode] Repeat tapped")
    }

    func handleNextAndMarkDone(in list: ShoppingList, markDone: (GroceryItem) -> Void) {
        guard let current = remainingItems(from: list).first else {
            updateStatus(.markDone, detail: "No remaining items")
            print("[ShoppingMode] Next/Mark Done tapped with no remaining items")
            return
        }

        markDone(current)
        updateStatus(.markDone, detail: "Completed \(current.name)")

        refreshQueue(from: list)
        if let next = visibleQueue.first {
            updateStatus(.advance, detail: "Now at \(next.name)")
        } else {
            updateStatus(.advance, detail: "All items completed")
        }

        readNextThree(in: list, reason: "advance")
        print("[ShoppingMode] Next/Mark Done tapped")
    }

    func stopSpeech() {
        speechService.stop()
    }

    private func readNextThree(in list: ShoppingList, reason: String) {
        refreshQueue(from: list)
        speechService.speak(items: visibleQueue, reason: reason)
        updateStatus(.readNextThree, detail: queueSummary())
    }

    private func refreshQueue(from list: ShoppingList) {
        visibleQueue = Array(remainingItems(from: list).prefix(3))
    }

    private func remainingItems(from list: ShoppingList) -> [GroceryItem] {
        list.items
            .filter { !$0.isChecked }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func queueSummary() -> String {
        guard !visibleQueue.isEmpty else { return "No remaining items" }
        return visibleQueue.map(\.name).joined(separator: ", ")
    }

    private func updateStatus(_ action: ShoppingAction, detail: String) {
        lastRecognizedActionText = "Last action: \(action.rawValue) • \(detail)"
        print("[ShoppingMode] Action: \(action.rawValue), status: \(lastRecognizedActionText)")
    }
}
