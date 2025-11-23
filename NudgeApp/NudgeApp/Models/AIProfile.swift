import Foundation
import CoreLocation

struct AIProfile: Codable {
    let userId: String
    var affinityVector: [Double]  // Learned preferences
    var frequentLocations: [FrequentLocation]
    var matchProbabilityMap: [String: Double]  // userId -> probability

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case affinityVector = "affinity_vector"
        case frequentLocations = "frequent_locations"
        case matchProbabilityMap = "match_probability_map"
    }
}

struct FrequentLocation: Identifiable, Codable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let venueName: String?
    let visitCount: Int
    let lastVisit: Date

    enum CodingKeys: String, CodingKey {
        case id
        case coordinate
        case venueName = "venue_name"
        case visitCount = "visit_count"
        case lastVisit = "last_visit"
    }
}

struct UserInteraction: Codable {
    let userId: String
    let targetUserId: String
    let interactionType: InteractionType
    let pauseTime: Double?  // seconds spent viewing
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case targetUserId = "target_user_id"
        case interactionType = "interaction_type"
        case pauseTime = "pause_time"
        case timestamp
    }
}

enum InteractionType: String, Codable {
    case viewed
    case liked
    case passed
    case matched
    case messaged
    case messageReceived = "message_received"
}
