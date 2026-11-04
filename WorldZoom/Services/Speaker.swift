import AVFoundation
import Foundation

/// Reads text out loud so Charlie doesn't have to decode every word to learn.
/// Auto-reading follows the "Read aloud" switch on the home screen; the
/// speaker buttons always talk.
final class Speaker {
    static let shared = Speaker()
    static let readAloudKey = "readAloud"

    private let synth = AVSpeechSynthesizer()

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    func say(_ text: String, force: Bool = false) {
        let autoRead = UserDefaults.standard.object(forKey: Self.readAloudKey) as? Bool ?? true
        guard force || autoRead else { return }
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
