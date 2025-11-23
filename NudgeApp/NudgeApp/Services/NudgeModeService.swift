import Foundation
import CoreLocation
import Combine

@MainActor
class NudgeModeService: ObservableObject {
    static let shared = NudgeModeService()

    @Published var nearbyUsers: [AnonymousNudge] = []
    @Published var receivedNudges: [Nudge] = []
    @Published var isActive = false
    @Published var currentRadius: Double = 30 // meters

    private let supabase = SupabaseClient.shared
    private let authService = AuthService.shared
    private let locationService = LocationService.shared

    private var updateTimer: Timer?

    private init() {}

    // MARK: - Nudge Mode Activation

    func activateNudgeMode() async {
        guard let currentUser = authService.currentUser,
              let currentLocation = locationService.currentLocation else {
            return
        }

        isActive = true
        locationService.enterNudgeMode()

        // Update user's precise location in ephemeral table
        do {
            try await supabase.database
                .from("nudge_mode_active_users")
                .insert([
                    "user_id": currentUser.id,
                    "location": [currentLocation.latitude, currentLocation.longitude],
                    "gender": currentUser.gender,
                    "timestamp": Date()
                ])
                .execute()
        } catch {
            print("Error activating nudge mode: \(error)")
        }

        // Start polling for nearby users
        startPolling()
    }

    func deactivateNudgeMode() async {
        guard let currentUser = authService.currentUser else { return }

        isActive = false
        locationService.exitNudgeMode()

        // Remove from active users
        do {
            try await supabase.database
                .from("nudge_mode_active_users")
                .delete()
                .eq("user_id", value: currentUser.id)
                .execute()
        } catch {
            print("Error deactivating nudge mode: \(error)")
        }

        stopPolling()
        nearbyUsers.removeAll()
    }

    // MARK: - Nearby User Detection

    private func startPolling() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchNearbyUsers()
                await self?.fetchReceivedNudges()
            }
        }

        Task {
            await fetchNearbyUsers()
            await fetchReceivedNudges()
        }
    }

    private func stopPolling() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func fetchNearbyUsers() async {
        guard let currentUser = authService.currentUser,
              let currentLocation = locationService.currentLocation else {
            return
        }

        do {
            // Fetch active users in Nudge Mode
            let activeUsers: [[String: Any]] = try await supabase.database
                .from("nudge_mode_active_users")
                .select()
                .neq("user_id", value: currentUser.id)
                .execute()
                .value

            // Filter by distance and preferences
            var nearby: [AnonymousNudge] = []

            for userDict in activeUsers {
                guard let userId = userDict["user_id"] as? String,
                      let locationArray = userDict["location"] as? [Double],
                      locationArray.count == 2,
                      let gender = userDict["gender"] as? String else {
                    continue
                }

                let userLocation = CLLocationCoordinate2D(
                    latitude: locationArray[0],
                    longitude: locationArray[1]
                )

                let distance = locationService.distance(from: userLocation) ?? Double.infinity

                // Check if within radius and matches preferences
                if distance <= currentRadius && currentUser.preferences.interestedIn.contains(gender) {
                    // Check if they've nudged you
                    let hasNudgedYou = receivedNudges.contains { $0.senderId == userId }

                    nearby.append(AnonymousNudge(
                        id: userId,
                        distance: distance,
                        gender: gender,
                        hasNudgedYou: hasNudgedYou
                    ))
                }
            }

            nearbyUsers = nearby.sorted { $0.distance < $1.distance }

        } catch {
            print("Error fetching nearby users: \(error)")
        }
    }

    // MARK: - Nudging

    func sendNudge(to anonymousUserId: String) async throws {
        guard let currentUser = authService.currentUser,
              let currentLocation = locationService.currentLocation else {
            return
        }

        let venueName = await locationService.getVenueName(for: currentLocation)

        let nudge = Nudge(
            id: UUID().uuidString,
            senderId: currentUser.id,
            receiverId: anonymousUserId,
            timestamp: Date(),
            locationContext: LocationContext(
                venueName: venueName,
                distance: locationService.distance(from: currentLocation) ?? 0,
                coordinate: currentLocation
            ),
            isRevealed: false
        )

        try await supabase.database
            .from("nudges")
            .insert(nudge)
            .execute()

        // Check for mutual nudge
        let reciprocalNudges: [Nudge] = try await supabase.database
            .from("nudges")
            .select()
            .eq("sender_id", value: anonymousUserId)
            .eq("receiver_id", value: currentUser.id)
            .execute()
            .value

        if !reciprocalNudges.isEmpty {
            // Mutual nudge! Create match
            try await createNudgeMatch(userId1: currentUser.id, userId2: anonymousUserId)
        }
    }

    private func fetchReceivedNudges() async {
        guard let currentUser = authService.currentUser else { return }

        do {
            let nudges: [Nudge] = try await supabase.database
                .from("nudges")
                .select()
                .eq("receiver_id", value: currentUser.id)
                .eq("is_revealed", value: false)
                .execute()
                .value

            receivedNudges = nudges
        } catch {
            print("Error fetching received nudges: \(error)")
        }
    }

    func respondToNudge(nudge: Nudge) async throws {
        guard let currentUser = authService.currentUser else { return }

        // Send nudge back
        try await sendNudge(to: nudge.senderId)

        // Create match (mutual nudge detected)
        try await createNudgeMatch(userId1: currentUser.id, userId2: nudge.senderId)
    }

    private func createNudgeMatch(userId1: String, userId2: String) async throws {
        let match = Match(
            id: UUID().uuidString,
            user1Id: userId1,
            user2Id: userId2,
            createdAt: Date(),
            expiredAt: Date().addingTimeInterval(72 * 3600), // 72 hours
            matchType: .nudge
        )

        try await supabase.database
            .from("matches")
            .insert(match)
            .execute()

        // Mark nudges as revealed
        try await supabase.database
            .from("nudges")
            .update(["is_revealed": true])
            .or("sender_id.eq.\(userId1),sender_id.eq.\(userId2)")
            .or("receiver_id.eq.\(userId1),receiver_id.eq.\(userId2)")
            .execute()

        // Refresh received nudges
        await fetchReceivedNudges()
    }

    // MARK: - Radius Adjustment

    func setRadius(_ radius: Double) {
        currentRadius = min(50, max(20, radius))
        Task {
            await fetchNearbyUsers()
        }
    }
}
