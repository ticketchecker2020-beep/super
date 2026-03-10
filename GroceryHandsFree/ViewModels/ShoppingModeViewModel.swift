import AVFoundation
import Foundation

@MainActor
final class ShoppingModeViewModel: NSObject, ObservableObject {
    @Published var currentlySpokenItemID: UUID?
    @Published var remoteCommandInput = ""

    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceItemIDs: [ObjectIdentifier: UUID] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func startGuidedFlow(with items: [GroceryItem], reason: String) {
        logQueueState(items, source: "start_guided_flow")
        speak(items: items, reason: reason)
    }

    func repeatQueue(_ items: [GroceryItem]) {
        print("[ShoppingMode] repeat_action")
        speak(items: items, reason: "repeat")
    }

    func readNextThree(_ items: [GroceryItem]) {
        print("[ShoppingMode] read_next_3")
        speak(items: items, reason: "read_next_3")
    }

    func handleRemoteInput(_ command: String, items: [GroceryItem], onMarkDone: () -> Void, onAdvance: () -> Void) {
        let normalized = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalized.isEmpty else { return }

        print("[ShoppingMode] remote_input_received: \(normalized)")

        switch normalized {
        case "repeat":
            repeatQueue(items)
        case "next", "advance":
            onAdvance()
        case "done", "mark_done":
            onMarkDone()
        case "read3", "read_next_3":
            readNextThree(items)
        case "queue":
            logQueueState(items, source: "remote_command")
        default:
            print("[ShoppingMode] remote_input_ignored: \(normalized)")
        }
    }

    func logQueueState(_ items: [GroceryItem], source: String) {
        let snapshot = items.prefix(3).map { "\($0.name)x\($0.quantity)" }.joined(separator: " | ")
        print("[ShoppingMode] queue_state(\(source)): [\(snapshot)]")
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
            let utterance = AVSpeechUtterance(string: speechText)
            utterance.voice = AVSpeechSynthesisVoice(language: "he-IL")
            utterance.rate = 0.48
            utterance.postUtteranceDelay = 0.2

            utteranceItemIDs[ObjectIdentifier(utterance)] = item.id
            synthesizer.speak(utterance)
        }

        print("[ShoppingMode] speech_start_queued(\(reason)): \(queue.map(\\.name).joined(separator: ", "))")
    }
}

extension ShoppingModeViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        currentlySpokenItemID = utteranceItemIDs[ObjectIdentifier(utterance)]
        if let currentlySpokenItemID {
            print("[ShoppingMode] speech_start item_id: \(currentlySpokenItemID)")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        utteranceItemIDs.removeValue(forKey: ObjectIdentifier(utterance))
        if !synthesizer.isSpeaking {
            currentlySpokenItemID = nil
        }
    }
}
