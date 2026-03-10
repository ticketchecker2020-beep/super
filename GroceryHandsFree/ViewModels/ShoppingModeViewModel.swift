import AVFoundation
import Foundation

@MainActor
final class ShoppingModeViewModel: NSObject, ObservableObject {
    @Published var currentlySpokenItemID: UUID?
    @Published var latestInstructionText = ""
    @Published var latestActionDescription = "Ready"

    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceItemIDs: [ObjectIdentifier: UUID] = [:]

    enum ShoppingControlAction: String {
        case singleTapAdvance = "single_tap_advance"
        case doubleTapRepeat = "double_tap_repeat"
        case longPressPreview = "long_press_preview"
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func startGuidedFlow(with items: [GroceryItem], reason: String) {
        print("[ShoppingMode] startGuidedFlow reason=\(reason) items=\(items.map(\\.name))")
        speak(items: items, reason: reason)
    }

    func repeatQueue(_ items: [GroceryItem]) {
        print("[ShoppingMode] Repeat queue request items=\(items.map(\\.name))")
        speak(items: items, reason: "repeat")
    }

    func handle(action: ShoppingControlAction, queue: [GroceryItem], executeAdvance: () -> Void) {
        switch action {
        case .singleTapAdvance:
            latestActionDescription = "Single tap: item completed"
            print("[ShoppingMode] Action single tap -> mark done and advance")
            executeAdvance()
        case .doubleTapRepeat:
            latestActionDescription = "Double tap: repeated last instruction"
            print("[ShoppingMode] Action double tap -> repeat last instruction")
            repeatLastInstructionOrQueue(queue)
        case .longPressPreview:
            latestActionDescription = "Long press: previewed next 3 items"
            print("[ShoppingMode] Action long press -> read next 3 items")
            readNextThreeItems(queue)
        }
    }

    func stopSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        utteranceItemIDs.removeAll()
        currentlySpokenItemID = nil
    }

    private func speak(items: [GroceryItem], reason: String) {
        let queue = Array(items.prefix(3))

        guard !queue.isEmpty else {
            stopSpeech()
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        utteranceItemIDs.removeAll()

        for (index, item) in queue.enumerated() {
            let prefix: String
            switch index {
            case 0: prefix = "פריט נוכחי"
            case 1: prefix = "הבא בתור"
            default: prefix = "אחריו"
            }

            let speechText = "\(prefix): \(item.name), כמות \(item.quantity)"
            if index == 0 {
                latestInstructionText = speechText
            }
            let utterance = AVSpeechUtterance(string: speechText)
            utterance.voice = AVSpeechSynthesisVoice(language: "he-IL")
            utterance.rate = 0.48
            utterance.postUtteranceDelay = 0.2

            utteranceItemIDs[ObjectIdentifier(utterance)] = item.id
            synthesizer.speak(utterance)
        }

        print("[ShoppingMode] Speech queued (\(reason)): \(queue.map(\\.name).joined(separator: ", "))")
    }

    private func repeatLastInstructionOrQueue(_ items: [GroceryItem]) {
        if !latestInstructionText.isEmpty {
            speak(text: latestInstructionText, reason: "repeat_last_instruction")
            return
        }

        speak(items: items, reason: "repeat_fallback_queue")
    }

    private func readNextThreeItems(_ items: [GroceryItem]) {
        speak(items: Array(items.prefix(3)), reason: "preview_next_three")
    }

    private func speak(text: String, reason: String) {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        utteranceItemIDs.removeAll()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "he-IL")
        utterance.rate = 0.48
        synthesizer.speak(utterance)
        print("[ShoppingMode] Speech queued (\(reason)): \(text)")
    }
}

extension ShoppingModeViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        currentlySpokenItemID = utteranceItemIDs[ObjectIdentifier(utterance)]
        if let currentlySpokenItemID {
            print("[ShoppingMode] Speech start item id: \(currentlySpokenItemID)")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        utteranceItemIDs.removeValue(forKey: ObjectIdentifier(utterance))
        if !synthesizer.isSpeaking {
            currentlySpokenItemID = nil
        }
    }
}
