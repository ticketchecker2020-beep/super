import AVFoundation
import Foundation

@MainActor
final class ShoppingModeViewModel: NSObject, ObservableObject {
    enum FlowState: Equatable {
        case idle
        case speaking
        case completed
    }

    @Published var currentlySpokenItemID: UUID?
    @Published private(set) var flowState: FlowState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceItemIDs: [ObjectIdentifier: UUID] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func startGuidedFlow(with items: [GroceryItem], reason: String) {
        print("[ShoppingMode] Start flow requested (\(reason)), itemCount=\(items.count)")
        speak(items: items, reason: reason)
    }

    func repeatQueue(_ items: [GroceryItem]) {
        print("[ShoppingMode] Repeat tapped")
        speak(items: items, reason: "repeat")
    }

    func stopSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        utteranceItemIDs.removeAll()
        currentlySpokenItemID = nil
        flowState = .idle
        print("[ShoppingMode] Speech stopped")
    }

    private func speak(items: [GroceryItem], reason: String) {
        let queue = Array(items.prefix(3))

        guard !queue.isEmpty else {
            stopSpeech()
            flowState = .completed
            print("[ShoppingMode] Flow completed - no remaining items")
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            currentlySpokenItemID = nil
        }

        utteranceItemIDs.removeAll()
        flowState = .speaking

        for (index, item) in queue.enumerated() {
            let prefix: String
            switch index {
            case 0: prefix = "פריט נוכחי"
            case 1: prefix = "הבא בתור"
            default: prefix = "אחריו"
            }

            let safeName = sanitizeSpokenText(item.name)
            let speechText = "\(prefix): \(safeName), כמות \(item.quantity)"
            let utterance = AVSpeechUtterance(string: speechText)
            utterance.voice = preferredHebrewVoice()
            utterance.rate = 0.48
            utterance.postUtteranceDelay = 0.2

            utteranceItemIDs[ObjectIdentifier(utterance)] = item.id
            synthesizer.speak(utterance)
        }

        print("[ShoppingMode] Speech queued (\(reason)): \(queue.map(\\.name).joined(separator: ", "))")
    }

    private func preferredHebrewVoice() -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(language: "he-IL") {
            return voice
        }

        print("[ShoppingMode] he-IL voice unavailable, using default voice")
        return AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
    }

    private func sanitizeSpokenText(_ value: String) -> String {
        let noControls = value.unicodeScalars.filter { !$0.properties.isControl }
        let flattened = String(String.UnicodeScalarView(noControls))
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let capped = String(flattened.prefix(80))
        return capped.isEmpty ? "פריט ללא שם" : capped
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
            flowState = .idle
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        utteranceItemIDs.removeValue(forKey: ObjectIdentifier(utterance))
        if !synthesizer.isSpeaking {
            currentlySpokenItemID = nil
            flowState = .idle
        }
    }
}
