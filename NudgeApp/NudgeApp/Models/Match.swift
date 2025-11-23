import Foundation

struct Match: Identifiable, Codable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
    let expiredAt: Date?
    var matchType: MatchType

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user_1"
        case user2Id = "user_2"
        case createdAt = "created_at"
        case expiredAt = "expired_at"
        case matchType = "match_type"
    }

    func otherUserId(currentUserId: String) -> String {
        return currentUserId == user1Id ? user2Id : user1Id
    }

    var isExpired: Bool {
        guard let expiredAt = expiredAt else { return false }
        return Date() > expiredAt
    }
}

enum MatchType: String, Codable {
    case regular = "regular"
    case nudge = "nudge"
}

struct Like: Identifiable, Codable {
    let id: String
    let userId: String
    let likedUserId: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case likedUserId = "liked_user_id"
        case timestamp
    }
}
