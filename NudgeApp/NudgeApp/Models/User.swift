import Foundation
import CoreLocation

struct User: Identifiable, Codable {
    let id: String
    var name: String
    var age: Int
    var gender: String
    var bio: String
    var photos: [String]  // URLs to uploaded photos
    var preferences: UserPreferences
    var approximateLocation: CLLocationCoordinate2D?
    var lastActive: Date
    var prompts: [Prompt]

    // Computed properties
    var primaryPhoto: String? {
        photos.first
    }

    enum CodingKeys: String, CodingKey {
        case id, name, age, gender, bio, photos, preferences
        case approximateLocation = "approximate_location"
        case lastActive = "last_active"
        case prompts
    }
}

struct UserPreferences: Codable {
    var minAge: Int
    var maxAge: Int
    var maxDistance: Int  // in km
    var interestedIn: [String]  // genders

    enum CodingKeys: String, CodingKey {
        case minAge = "min_age"
        case maxAge = "max_age"
        case maxDistance = "max_distance"
        case interestedIn = "interested_in"
    }
}

struct Prompt: Identifiable, Codable {
    let id: String
    var question: String
    var answer: String
}

// Extension for CLLocationCoordinate2D Codable support
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(CLLocationDegrees.self)
        let longitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}
