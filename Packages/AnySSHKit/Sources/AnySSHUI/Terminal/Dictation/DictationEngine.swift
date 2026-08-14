#if canImport(UIKit)
import AVFoundation
import AudioToolbox
import Observation
import Speech

@MainActor
@Observable
public final class DictationEngine {
    public enum State: Equatable {
        case idle
        case listening
        case denied(reason: String)
        case unavailable(reason: String)
    }

    public private(set) var state = State.idle
    public private(set) var transcript = ""

    public var onFinish: ((String) -> Void)?

    private let silence = Duration.milliseconds(1_600)
    private var silenceTimer: Task<Void, Never>?

    private let recognizer = SFSpeechRecognizer()
    private let audio = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    public init() {}

    public var isListening: Bool { state == .listening }

    public func start() async {
        guard state != .listening else { return }
        transcript = ""
        guard await requestPermission() else { return }
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Speech recognition is not available for this language.")
            return
        }
        guard recognizer.supportsOnDeviceRecognition else {
            state = .unavailable(
                reason: "This device cannot recognise speech without sending it to a server."
            )
            return
        }
        do {
            try beginCapture(with: recognizer)
            state = .listening
            AudioServicesPlaySystemSound(1113)
        } catch {
            state = .unavailable(reason: "The microphone could not be started.")
        }
    }

    public func stop() {
        let finished = state == .listening
        silenceTimer?.cancel()
        silenceTimer = nil
        audio.stop()
        audio.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        if state == .listening { state = .idle }
        guard finished else { return }
        AudioServicesPlaySystemSound(1114)
        let heard = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        transcript = ""
        guard !heard.isEmpty else { return }
        onFinish?(heard)
    }

    private func noteHeardSomething() {
        silenceTimer?.cancel()
        silenceTimer = Task { [silence] in
            try? await Task.sleep(for: silence)
            guard !Task.isCancelled else { return }
            stop()
        }
    }

    public func clear() {
        transcript = ""
    }

    private func beginCapture(with recognizer: SFSpeechRecognizer) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        Self.installTap(on: audio.inputNode, feeding: request)
        audio.prepare()
        try audio.start()
        task = Self.recognize(request, with: recognizer) { [weak self] transcript, finished in
            Task { @MainActor in
                guard let self else { return }
                if let transcript {
                    self.transcript = transcript
                    self.noteHeardSomething()
                }
                if finished { self.stop() }
            }
        }
    }

    private nonisolated static func installTap(
        on input: AVAudioInputNode,
        feeding request: SFSpeechAudioBufferRecognitionRequest
    ) {
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) {
            buffer, _ in
            request.append(buffer)
        }
    }

    private nonisolated static func recognize(
        _ request: SFSpeechAudioBufferRecognitionRequest,
        with recognizer: SFSpeechRecognizer,
        onUpdate: @escaping @Sendable (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            onUpdate(
                result?.bestTranscription.formattedString,
                error != nil || result?.isFinal == true
            )
        }
    }

    private nonisolated func speechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }

    private func requestPermission() async -> Bool {
        let speech = await speechAuthorization()
        guard speech == .authorized else {
            state = .denied(reason: "Dictation needs permission to recognise speech.")
            return false
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard microphone else {
            state = .denied(reason: "Dictation needs access to the microphone.")
            return false
        }
        return true
    }
}
#endif
