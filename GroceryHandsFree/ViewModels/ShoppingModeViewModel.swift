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
        perform(.readNextThree, with: list)
    }

    func perform(_ action: ShoppingAction, with list: ShoppingList, markDone: ((GroceryItem) -> Void)? = nil) {
        switch action {
        case .repeatQueue:
            refreshQueue(from: list)
            speechService.speak(items: visibleQueue, reason: "repeat")
            updateStatus(action, detail: queueSummary())

        case .markDone:
            guard let current = remainingItems(from: list).first else {
                updateStatus(action, detail: "No remaining items")
                return
            }

            markDone?(current)
            refreshQueue(from: list)
            updateStatus(action, detail: "Completed \(current.name)")

        case .advance:
            refreshQueue(from: list)
            if let next = visibleQueue.first {
                updateStatus(action, detail: "Now at \(next.name)")
            } else {
                updateStatus(action, detail: "All items completed")
            }

        case .readNextThree:
            refreshQueue(from: list)
            speechService.speak(items: visibleQueue, reason: "read-next-3")
            updateStatus(action, detail: queueSummary())
        }

        print("[ShoppingMode] Action: \(action.rawValue), status: \(lastRecognizedActionText)")
    }

    func stopSpeech() {
        speechService.stop()
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
    }
}
