import Foundation

struct TalkHistory {
    let role: TalkRole
    let content: String
}

enum TalkRole: String {
    case user
    case assistant
    case system
}
