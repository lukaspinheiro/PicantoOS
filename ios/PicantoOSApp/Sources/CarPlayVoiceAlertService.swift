import AVFoundation
import Foundation

/// Speaks critical vehicle alerts over the car's CarPlay audio channel,
/// temporarily ducking music via AVAudioSession.
@MainActor
final class CarPlayVoiceAlertService {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastAlertTimestamp: [String: Date] = [:]
    private let cooldownSeconds: TimeInterval = 30

    func speakIfNeeded(key: String, message: String) {
        let now = Date()
        if let last = lastAlertTimestamp[key], now.timeIntervalSince(last) < cooldownSeconds {
            return
        }
        lastAlertTimestamp[key] = now

        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true)
        } catch {
            // Best-effort audio session configuration
        }
        #endif

        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
