import SwiftUI
import Combine

struct ContentView: View {
    @State private var prompt = ""

    @StateObject var speechRecognizerViewModel = SpeechRecognizerViewModel()
    @StateObject var textToSpeechViewModel = TextToSpeechViewModel()
    @StateObject var textCompletionViewModel = TextCompletionViewModel(apiClient: OpenAIAPI())

    var body: some View {
        VStack {
            Text(speechRecognizerViewModel.state.titleString).font(.title)
            UserTextView(userText: $speechRecognizerViewModel.userText)
            AssistantTextView(assistantText: $speechRecognizerViewModel.assistantText)
            ControlsView(speechRecognizerViewModel: speechRecognizerViewModel,
                         textCompletionViewModel: textCompletionViewModel,
                         textToSpeechViewModel: textToSpeechViewModel)
        }
        .padding()
        .onAppear {
            speechRecognizerViewModel.requestAuthorization()
        }
        .onReceive(speechRecognizerViewModel.$isInputFinished.removeDuplicates().dropFirst()) { isInputFinished in
            if !isInputFinished {
                speechRecognizerViewModel.stop()
                try? speechRecognizerViewModel.record()
            }

            // ユーザーの音声入力が終わり、何らかの入力がある
            guard isInputFinished, !speechRecognizerViewModel.userText.isEmpty else { return }
            
            // GPTからのレスポンスを取得
            textCompletionViewModel
                .generateResponse(prompt: speechRecognizerViewModel.userText)
                .catch { error -> AnyPublisher<ChatCompletion, Never> in
                    print("Error: \(error.localizedDescription)")
                    return Empty().eraseToAnyPublisher()
                }
                .receive(on: DispatchQueue.main)
                .flatMap { chat -> AnyPublisher<Void, Never> in
                    speechRecognizerViewModel.assistantText = chat.choices?.first?.message?.content ?? ""

                    if !speechRecognizerViewModel.assistantText.isEmpty {
                        textCompletionViewModel.addAssistantHistory(content: speechRecognizerViewModel.assistantText)
                    }
                    
                    // レスポンス内容を発話
                    return textToSpeechViewModel.convertTextToSpeech(text: speechRecognizerViewModel.assistantText)
                }
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    // レスポンスの発話が完了してから再度レコーディング状態に戻す
                    speechRecognizerViewModel.isInputFinished = false
                }
                .store(in: &speechRecognizerViewModel.subscriptions)
        }
    }
}

struct UserTextView: View {
    @Binding var userText: String

    var body: some View {
        Text(userText)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct AssistantTextView: View {
    @Binding var assistantText: String

    var body: some View {
        Text(assistantText)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .backgroundStyle(.brown)
    }
}

struct ControlsView: View {
    @ObservedObject var speechRecognizerViewModel: SpeechRecognizerViewModel
    @ObservedObject var textCompletionViewModel: TextCompletionViewModel
    @ObservedObject var textToSpeechViewModel: TextToSpeechViewModel

    var body: some View {
        HStack {
            ClearButton(speechRecognizerViewModel: speechRecognizerViewModel)
        }
        .padding()
    }
}

struct ClearButton: View {
    @ObservedObject var speechRecognizerViewModel: SpeechRecognizerViewModel

    var body: some View {
        Button(action: {
            speechRecognizerViewModel.clearAssistantText()
            speechRecognizerViewModel.clearUserText()
        }, label: {
            Image(systemName: "trash.circle")
                .resizable().scaledToFit()
                .frame(width: 50, height: 50)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
