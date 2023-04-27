import Foundation
import Combine

final class TextCompletionViewModel: ObservableObject {

    @Published private(set) var talkHistories: [TalkHistory] = []

    private let apiClient: OpenAIAPI

    // 会話の履歴を最大何個まで保持するか
    private let maxContextCount = 3

    init(apiClient: OpenAIAPI) {
        self.apiClient = apiClient
    }

    func addAssistantHistory(content: String) {
        talkHistories.append(TalkHistory(role: .assistant, content: content))
    }

    func clearTalkHistory() {
        talkHistories = []
    }

    // システムロールを任意の数追加する
    // ここでは会話の練習のためにレスポンスは短く返すように指示を入れている
    private func makeSystemPrompts() -> [TalkHistory] {
        return [
            TalkHistory(role: .system, content: "This is intended for English conversation practice. Please provide concise responses and ask relevant questions to keep the conversation going")
        ]
    }
    
    func generateResponse(prompt: String) -> AnyPublisher<ChatCompletion, Error> {
         talkHistories.append(TalkHistory(role: .user, content: prompt))

         if talkHistories.count > maxContextCount {
             talkHistories.removeFirst()
         }

         let messages = (makeSystemPrompts() + talkHistories)
             .map { prompt in ["role": prompt.role.rawValue, "content": prompt.content] }

         return apiClient.generateResponse(messages: messages)
     }
}
