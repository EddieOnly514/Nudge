import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let matchId: String
    let senderId: String
    let text: String
    let timestamp: Date
    var aiFlagged: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case senderId = "sender_id"
        case text
        case timestamp
        case aiFlagged = "ai_flagged"
    }

    var isSentByCurrentUser: Bool {
        // Will be computed in the view
        false
    }
}

struct Conversation: Identifiable {
    let id: String
    let match: Match
    let otherUser: User
    var messages: [ChatMessage]
    var lastMessage: ChatMessage?

    var lastMessagePreview: String {
        lastMessage?.text ?? "Start chatting..."
    }

    var lastMessageTime: Date? {
        lastMessage?.timestamp
    }
}
