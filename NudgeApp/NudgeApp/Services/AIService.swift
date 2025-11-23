import Foundation

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    private let supabase = SupabaseClient.shared
    private let openAIKey = SupabaseConfig.openAIKey

    private init() {}

    // MARK: - User Ranking (Affinity-Based)

    func rankUsers(_ users: [User], for currentUser: User) async -> [User] {
        // Fetch AI profile
        guard let aiProfile = try? await fetchAIProfile(userId: currentUser.id) else {
            return users.shuffled() // Fallback to random
        }

        // Calculate affinity scores
        var scoredUsers: [(user: User, score: Double)] = users.map { user in
            let score = calculateAffinityScore(
                currentUser: currentUser,
                targetUser: user,
                aiProfile: aiProfile
            )
            return (user, score)
        }

        // Sort by score descending
        scoredUsers.sort { $0.score > $1.score }

        return scoredUsers.map { $0.user }
    }

    private func calculateAffinityScore(currentUser: User, targetUser: User, aiProfile: AIProfile) -> Double {
        var score = 0.0

        // Historical match probability
        if let historicalProbability = aiProfile.matchProbabilityMap[targetUser.id] {
            score += historicalProbability * 0.4
        }

        // Proximity bonus
        if let currentLocation = currentUser.approximateLocation,
           let targetLocation = targetUser.approximateLocation {
            let distance = LocationService.shared.distance(from: targetLocation) ?? Double.infinity
            let proximityScore = max(0, 1 - (distance / 10000)) // 10km max
            score += proximityScore * 0.3
        }

        // Frequent location overlap
        if let currentLocation = currentUser.approximateLocation {
            let hasFrequentLocationNearby = aiProfile.frequentLocations.contains { location in
                let distance = LocationService.shared.distance(from: location.coordinate) ?? Double.infinity
                return distance < 500 // 500m
            }
            if hasFrequentLocationNearby {
                score += 0.2
            }
        }

        // Recency boost
        if let lastActive = targetUser.lastActive {
            let hoursSinceActive = Date().timeIntervalSince(lastActive) / 3600
            if hoursSinceActive < 24 {
                score += 0.1
            }
        }

        return score
    }

    // MARK: - Interaction Tracking

    func trackInteraction(userId: String, targetUserId: String, type: InteractionType, pauseTime: Double? = nil) async {
        let interaction = UserInteraction(
            userId: userId,
            targetUserId: targetUserId,
            interactionType: type,
            pauseTime: pauseTime,
            timestamp: Date()
        )

        do {
            try await supabase.database
                .from("user_interactions")
                .insert(interaction)
                .execute()

            // Update affinity model asynchronously
            Task {
                await updateAffinityModel(userId: userId)
            }
        } catch {
            print("Error tracking interaction: \(error)")
        }
    }

    private func updateAffinityModel(userId: String) async {
        // Simplified affinity update - in production, this would be more sophisticated
        do {
            let interactions: [UserInteraction] = try await supabase.database
                .from("user_interactions")
                .select()
                .eq("user_id", value: userId)
                .order("timestamp", ascending: false)
                .limit(100)
                .execute()
                .value

            // Calculate match probabilities based on interactions
            var matchProbabilities: [String: Double] = [:]

            for interaction in interactions {
                let currentProb = matchProbabilities[interaction.targetUserId] ?? 0.5

                switch interaction.interactionType {
                case .liked:
                    matchProbabilities[interaction.targetUserId] = min(1.0, currentProb + 0.2)
                case .matched:
                    matchProbabilities[interaction.targetUserId] = 0.9
                case .messaged:
                    matchProbabilities[interaction.targetUserId] = min(1.0, currentProb + 0.1)
                case .passed:
                    matchProbabilities[interaction.targetUserId] = max(0.0, currentProb - 0.3)
                default:
                    break
                }
            }

            // Update AI profile
            try await supabase.database
                .from("ai_profiles")
                .update(["match_probability_map": matchProbabilities])
                .eq("user_id", value: userId)
                .execute()

        } catch {
            print("Error updating affinity model: \(error)")
        }
    }

    // MARK: - AI Profile Management

    func fetchAIProfile(userId: String) async throws -> AIProfile {
        let response: AIProfile = try await supabase.database
            .from("ai_profiles")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        return response
    }

    func createAIProfile(userId: String) async throws {
        let profile = AIProfile(
            userId: userId,
            affinityVector: Array(repeating: 0.5, count: 10),
            frequentLocations: [],
            matchProbabilityMap: [:]
        )

        try await supabase.database
            .from("ai_profiles")
            .insert(profile)
            .execute()
    }

    // MARK: - Contextual Suggestions

    func generateContextualSuggestion(for user: User, at location: CLLocationCoordinate2D) async -> String? {
        guard let venueName = await LocationService.shared.getVenueName(for: location) else {
            return nil
        }

        // Check if user frequents this location
        if let aiProfile = try? await fetchAIProfile(userId: user.id) {
            let frequentsHere = aiProfile.frequentLocations.contains { location in
                let distance = LocationService.shared.distance(from: location.coordinate) ?? Double.infinity
                return distance < 100
            }

            if frequentsHere {
                return "You're at \(venueName) — \(user.name) is often here too."
            }
        }

        return "People near \(venueName)"
    }

    // MARK: - AI Chat Assistant

    func generateMessageSuggestions(for match: Match, conversation: [ChatMessage]) async -> [String] {
        // Simple rule-based suggestions for MVP
        // In production, use OpenAI API

        if conversation.isEmpty {
            return [
                "Hey! How's your day going?",
                "Hi \(match.otherUserId(currentUserId: ""))! Great to match with you",
                "Hey there! What brings you to the app?"
            ]
        }

        return [
            "That sounds interesting!",
            "Tell me more about that",
            "What do you like to do for fun?"
        ]
    }

    func generateFirstMessageIdea(for user: User) async -> String? {
        // Pick a random prompt to reference
        guard let prompt = user.prompts.randomElement() else {
            return nil
        }

        return "Ask about: \(prompt.question)"
    }

    // MARK: - Safety Filter

    func filterMessage(_ message: String) async -> Bool {
        // Simple keyword filter for MVP
        // In production, use OpenAI moderation API

        let inappropriateKeywords = [
            "explicit", "inappropriate", "harassment"
            // Add more keywords
        ]

        let lowercased = message.lowercased()
        return inappropriateKeywords.contains { lowercased.contains($0) }
    }

    func moderateMessage(_ message: String) async throws -> Bool {
        // Call OpenAI Moderation API
        guard !openAIKey.isEmpty, openAIKey != "YOUR_OPENAI_API_KEY" else {
            return await filterMessage(message)
        }

        let url = URL(string: "https://api.openai.com/v1/moderations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["input": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ModerationResponse.self, from: data)

        return response.results.first?.flagged ?? false
    }
}

// MARK: - OpenAI Response Models

struct ModerationResponse: Codable {
    let results: [ModerationResult]
}

struct ModerationResult: Codable {
    let flagged: Bool
    let categories: [String: Bool]
}
