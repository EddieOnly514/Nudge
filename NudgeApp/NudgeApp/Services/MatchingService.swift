import Foundation
import Combine

@MainActor
class MatchingService: ObservableObject {
    static let shared = MatchingService()

    @Published var feedUsers: [User] = []
    @Published var matches: [Match] = []
    @Published var isLoading = false

    private let supabase = SupabaseClient.shared
    private let authService = AuthService.shared
    private let aiService = AIService.shared

    private init() {}

    // MARK: - Feed Generation

    func fetchFeed() async {
        guard let currentUser = authService.currentUser else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch potential matches based on preferences
            let response: [User] = try await supabase.database
                .from("users")
                .select()
                .neq("id", value: currentUser.id)
                .gte("age", value: currentUser.preferences.minAge)
                .lte("age", value: currentUser.preferences.maxAge)
                .in("gender", values: currentUser.preferences.interestedIn)
                .limit(50)
                .execute()
                .value

            // Filter by distance
            var filteredUsers = response.filter { user in
                guard let userLocation = user.approximateLocation,
                      let currentLocation = currentUser.approximateLocation else {
                    return false
                }

                let distance = LocationService.shared.distance(from: userLocation) ?? Double.infinity
                return distance <= Double(currentUser.preferences.maxDistance * 1000)
            }

            // Get already liked/passed users
            let interactedUserIds = try await getInteractedUserIds(userId: currentUser.id)
            filteredUsers = filteredUsers.filter { !interactedUserIds.contains($0.id) }

            // AI ranking
            let rankedUsers = await aiService.rankUsers(filteredUsers, for: currentUser)

            feedUsers = rankedUsers
        } catch {
            print("Error fetching feed: \(error)")
        }
    }

    private func getInteractedUserIds(userId: String) async throws -> Set<String> {
        let likes: [Like] = try await supabase.database
            .from("likes")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        let passes: [Like] = try await supabase.database
            .from("passes")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return Set(likes.map { $0.likedUserId } + passes.map { $0.likedUserId })
    }

    // MARK: - Liking & Matching

    func likeUser(_ user: User) async throws {
        guard let currentUser = authService.currentUser else { return }

        // Record the like
        let like = Like(
            id: UUID().uuidString,
            userId: currentUser.id,
            likedUserId: user.id,
            timestamp: Date()
        )

        try await supabase.database
            .from("likes")
            .insert(like)
            .execute()

        // Track interaction for AI
        await aiService.trackInteraction(
            userId: currentUser.id,
            targetUserId: user.id,
            type: .liked
        )

        // Check if it's a match
        let reciprocalLike: [Like]? = try? await supabase.database
            .from("likes")
            .select()
            .eq("user_id", value: user.id)
            .eq("liked_user_id", value: currentUser.id)
            .execute()
            .value

        if let reciprocalLike = reciprocalLike, !reciprocalLike.isEmpty {
            // Create match
            try await createMatch(user1Id: currentUser.id, user2Id: user.id, type: .regular)
        }

        // Remove from feed
        feedUsers.removeAll { $0.id == user.id }
    }

    func passUser(_ user: User) async throws {
        guard let currentUser = authService.currentUser else { return }

        // Record the pass
        let pass = Like(
            id: UUID().uuidString,
            userId: currentUser.id,
            likedUserId: user.id,
            timestamp: Date()
        )

        try await supabase.database
            .from("passes")
            .insert(pass)
            .execute()

        // Track interaction for AI
        await aiService.trackInteraction(
            userId: currentUser.id,
            targetUserId: user.id,
            type: .passed
        )

        // Remove from feed
        feedUsers.removeAll { $0.id == user.id }
    }

    private func createMatch(user1Id: String, user2Id: String, type: MatchType) async throws {
        let match = Match(
            id: UUID().uuidString,
            user1Id: user1Id,
            user2Id: user2Id,
            createdAt: Date(),
            expiredAt: nil,
            matchType: type
        )

        try await supabase.database
            .from("matches")
            .insert(match)
            .execute()

        matches.append(match)

        // Track for AI
        await aiService.trackInteraction(userId: user1Id, targetUserId: user2Id, type: .matched)
        await aiService.trackInteraction(userId: user2Id, targetUserId: user1Id, type: .matched)
    }

    // MARK: - Fetch Matches

    func fetchMatches() async {
        guard let currentUser = authService.currentUser else { return }

        do {
            let response: [Match] = try await supabase.database
                .from("matches")
                .select()
                .or("user_1.eq.\(currentUser.id),user_2.eq.\(currentUser.id)")
                .order("created_at", ascending: false)
                .execute()
                .value

            matches = response.filter { !$0.isExpired }
        } catch {
            print("Error fetching matches: \(error)")
        }
    }
}
