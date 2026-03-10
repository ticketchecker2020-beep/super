import AVFoundation
import Foundation

@MainActor
final class SpeechService: NSObject {
    var onDidStartItem: ((UUID?) -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceItemIDs: [ObjectIdentifier: UUID] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(items: [GroceryItem], reason: String) {
        guard !items.isEmpty else {
            stop()
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        utteranceItemIDs.removeAll()

        for (index, item) in items.enumerated() {
            let prefix: String
            switch index {
            case 0: prefix = "פריט נוכחי"
            case 1: prefix = "הבא בתור"
            default: prefix = "אחריו"
            }

            let utterance = AVSpeechUtterance(string: "\(prefix): \(item.name), כמות \(item.quantity)")
            utterance.voice = AVSpeechSynthesisVoice(language: "he-IL")
            utterance.rate = 0.48
            utterance.postUtteranceDelay = 0.2

            utteranceItemIDs[ObjectIdentifier(utterance)] = item.id
            synthesizer.speak(utterance)
        }

        print("[SpeechService] Queued speech (\(reason)): \(items.map(\\.name).joined(separator: ", "))")
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        utteranceItemIDs.removeAll()
        onDidStartItem?(nil)
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onDidStartItem?(utteranceItemIDs[ObjectIdentifier(utterance)])
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        utteranceItemIDs.removeValue(forKey: ObjectIdentifier(utterance))
        if !synthesizer.isSpeaking {
            onDidStartItem?(nil)
        }
    }
}
