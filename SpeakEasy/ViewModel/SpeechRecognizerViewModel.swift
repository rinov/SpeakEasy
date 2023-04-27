import Foundation
import Speech
import Combine

enum AppState: Equatable {
    case notRecording
    case recording(AVAudioInputNode, SFSpeechRecognitionTask)
    
    var isRecording: Bool {
        return self != .notRecording
    }
    
    var titleString: String {
        return "SpeakEasy"
    }
}

@MainActor
class SpeechRecognizerViewModel: ObservableObject {
    @Published var state: AppState = .notRecording
    @Published var userText: String = ""
    @Published var assistantText: String = ""
    @Published var isInputFinished = false

    var subscriptions = Set<AnyCancellable>()

    // ユーザーの音声入力が止まってから何秒後で入力が終わったとみなすか
    private let waitsForResponseSec = 2.0
    private let audioSession = AVAudioSession.sharedInstance()
    private let audioEngine = AVAudioEngine()

    private var silenceTimer: Timer?

    private var speechRecognizer: SFSpeechRecognizer {
        // NOTE: Localeによって音声入力の言語を変更可能 e.g. ja-JP
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer else { fatalError("Failed to prepare recognizer")}
        recognizer.supportsOnDeviceRecognition = true
        return recognizer
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] _ in
            try? self?.record()
        }
    }
    
    func clearUserText() {
        self.userText = ""
    }

    func clearAssistantText() {
        self.assistantText = ""
    }

    func stop() {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return }
        
        if case .recording(let node,let task) = self.state {
            self.audioEngine.stop()
            node.removeTap(onBus: 0)
            task.finish()
            self.state = .notRecording
        }
    }
    
    func record() throws {
        guard state == .notRecording, SFSpeechRecognizer.authorizationStatus() == .authorized else { return }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        // 音声入力内容をリアルタイムに部分認識していくようにする
        recognitionRequest.shouldReportPartialResults = true

        // 音声認識の速度を向上するためにオンデバイス処理を有効にする(※falseにすることによって精度は向上する)
        recognitionRequest.requiresOnDeviceRecognition = true

        try self.audioSession.setCategory(.record, mode: .default, options: .duckOthers)
        try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            if let result = result?.bestTranscription.formattedString, !result.isEmpty {
                self.userText = result
                self.handleSilenceTimer()
            }
        })

        let inputNode = self.audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // 音声の入力があるたびにどれくらいバッファとして取得するかを指定
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.state = .recording(inputNode, recognitionTask)
        }
    }

    private func handleSilenceTimer() {
        silenceTimer?.invalidate()

        silenceTimer = Timer.scheduledTimer(withTimeInterval: waitsForResponseSec, repeats: false) { _ in
            DispatchQueue.main.async {
                self.stop()
                self.isInputFinished = true
            }
        }
    }
}
