import Foundation
import CoreLocation

struct Nudge: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let timestamp: Date
    let locationContext: LocationContext?
    var isRevealed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case timestamp
        case locationContext = "location_context"
        case isRevealed = "is_revealed"
    }
}

struct LocationContext: Codable {
    let venueName: String?
    let distance: Double  // in meters
    let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case venueName = "venue_name"
        case distance
        case coordinate
    }
}

// Anonymous representation for UI
struct AnonymousNudge: Identifiable {
    let id: String
    let distance: Double
    let gender: String
    let hasNudgedYou: Bool
}
