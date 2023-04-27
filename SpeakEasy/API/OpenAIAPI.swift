import Foundation
import Combine

class OpenAIAPI {
    private let apiKey = CredentialManager.shared.value(for: CredentialKey.openAiKey)
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func generateResponse(messages: [[String: String]]) -> AnyPublisher<ChatCompletion, Error> {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo", // 正確性よりも応答速度を重視するモデル
            "messages": messages,
            "top_p": 1,
            "n": 1,
            "max_tokens": 25, // 返却される最大トークン数を小さくすることで会話をスムーズにする
            "frequency_penalty": 1.5, // 同じ単語ばかりが返されないようにランダム性を向上する (-2~2, 2が最もランダム)
            "presence_penalty": 1
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode else {
                        throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ChatCompletion.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
