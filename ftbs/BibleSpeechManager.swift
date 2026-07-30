import AVFoundation
import Combine
import Foundation

struct SpeechVoiceOption: Identifiable, Hashable, Codable, Sendable {
    let identifier: String
    let name: String
    let languageCode: String
    let quality: String

    var id: String { identifier }

    var displayName: String { name }

    var subtitle: String { "\(languageCode) • \(quality)" }
}

private extension BibleLanguage {
    var speechLanguageCode: String {
        switch self {
        case .telugu: return "te-IN"
        case .english: return "en-US"
        case .hindi: return "hi-IN"
        case .kannada: return "kn-IN"
        case .malayalam: return "ml-IN"
        case .tamil: return "ta-IN"
        }
    }
}

@MainActor
final class BibleSpeechManager: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    @Published private(set) var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: BibleLanguage, voiceIdentifier: String?, rate: Double) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            stop()
            return
        }

        configureAudioSessionIfNeeded()
        stop()

        let utterance = AVSpeechUtterance(string: trimmedText)
        utterance.voice = preferredVoice(for: language, voiceIdentifier: voiceIdentifier)
        utterance.rate = speechRate(for: rate)
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        isPaused = false
        synthesizer.speak(utterance)
    }

    func pause() {
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPaused = true
        isSpeaking = false
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        isSpeaking = true
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
    }

    func availableVoiceOptions(for language: BibleLanguage) -> [SpeechVoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { isVoiceCompatible($0, with: language.speechLanguageCode) }
            .sorted { lhs, rhs in
                if isNativeVoice(lhs, for: language.speechLanguageCode) != isNativeVoice(rhs, for: language.speechLanguageCode) {
                    return isNativeVoice(lhs, for: language.speechLanguageCode)
                }

                if lhs.quality.rawValue != rhs.quality.rawValue {
                    return lhs.quality.rawValue > rhs.quality.rawValue
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .map {
                SpeechVoiceOption(
                    identifier: $0.identifier,
                    name: $0.name,
                    languageCode: $0.language,
                    quality: qualityDescription(for: $0.quality)
                )
            }
    }

    private func preferredVoice(for language: BibleLanguage, voiceIdentifier: String?) -> AVSpeechSynthesisVoice? {
        let languageCode = language.speechLanguageCode
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()

        if let voiceIdentifier,
           let selectedVoice = availableVoices.first(where: { $0.identifier == voiceIdentifier }) {
            return selectedVoice
        }

        let preferredVoices = availableVoices.filter { isVoiceCompatible($0, with: languageCode) }

        if let exactNativeVoice = preferredVoices.first(where: { isNativeVoice($0, for: languageCode) }) {
            return exactNativeVoice
        }

        if let exact = AVSpeechSynthesisVoice(language: languageCode) {
            return exact
        }

        return AVSpeechSynthesisVoice(language: "en-US")
    }

    private func isVoiceCompatible(_ voice: AVSpeechSynthesisVoice, with languageCode: String) -> Bool {
        voice.language == languageCode || voice.language.hasPrefix(languageCode.prefix(2))
    }

    private func isNativeVoice(_ voice: AVSpeechSynthesisVoice, for languageCode: String) -> Bool {
        voice.language == languageCode
    }

    private func qualityDescription(for quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .default: return "Standard"
        case .enhanced: return "Enhanced"
        case .premium: return "Premium"
        @unknown default: return "Voice"
        }
    }

    private func speechRate(for rate: Double) -> Float {
        let clamped = min(max(rate, 0.5), 1.5)
        return Float(clamped * 0.5)
    }

    private func configureAudioSessionIfNeeded() {
#if canImport(UIKit)
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Leave speech synthesis best-effort; the utterance guard still prevents invalid buffers.
        }
#endif
    }

}

extension BibleSpeechManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}
