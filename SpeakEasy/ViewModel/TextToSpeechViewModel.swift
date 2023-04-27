import Combine
import Foundation
import AVFoundation
import AWSPolly

@MainActor
final class TextToSpeechViewModel: NSObject, ObservableObject {
    
    private var player: AVAudioPlayer?
    private var playCompletion: ((Result<Void, Never>) -> Void)?

    private let polly = AWSPolly.default()
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {}

    func convertTextToSpeech(text: String) -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { [weak self] promise in
            guard let me = self, let input = AWSPollySynthesizeSpeechInput() else {
                promise(.success(()))
                return
            }

            me.playCompletion = promise

            // 詳細はAWSPollyのSampleなどを参照: https://github.com/awslabs/aws-sdk-ios-samples/tree/main/Polly-Sample/Swift
            // engineをneuralにそれに対応したvoiceIdを選択することによって、自然な発音にトレーニングされたモデルを利用することができる
            input.text = text
            input.outputFormat = .mp3
            input.engine = .neural
            input.textType = .text
            input.voiceId = .ivy
            
            me.polly.synthesizeSpeech(input) { (response, error) in
                if let audioStream = response?.audioStream {
                    guard let me = self else { return }
                    me.player = try? AVAudioPlayer(data: audioStream)
                    me.player?.delegate = me

                    do {
                        try me.audioSession.setCategory(.playback, mode: .default)
                        try me.audioSession.setActive(true)
                    } catch let error {
                        print("Error setting up audio session: \(error.localizedDescription)")
                    }
                    me.player?.play()
                } else {
                    print("Error occurred: \(error?.localizedDescription ?? "Unknown error")")
                    me.playCompletion?(.success(()))
                    me.playCompletion = nil
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension TextToSpeechViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playCompletion?(.success(()))
        playCompletion = nil
    }
}
