import Foundation
import Supabase
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    private let supabase = SupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkAuthStatus()
    }

    // MARK: - Authentication Status

    func checkAuthStatus() {
        Task {
            do {
                if let session = try await supabase.auth.session {
                    isAuthenticated = true
                    await fetchCurrentUser(userId: session.user.id.uuidString)
                } else {
                    isAuthenticated = false
                    currentUser = nil
                }
            } catch {
                print("Error checking auth status: \(error)")
                isAuthenticated = false
            }
        }
    }

    // MARK: - Phone Authentication

    func sendOTP(phoneNumber: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.signInWithOTP(
            phone: phoneNumber
        )
    }

    func verifyOTP(phoneNumber: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.verifyOTP(
            phone: phoneNumber,
            token: code,
            type: .sms
        )

        isAuthenticated = true
        await fetchCurrentUser(userId: session.user.id.uuidString)
    }

    // MARK: - User Management

    private func fetchCurrentUser(userId: String) async {
        do {
            let response: User = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            currentUser = response
        } catch {
            print("Error fetching user: \(error)")
        }
    }

    func createUserProfile(name: String, age: Int, gender: String, photos: [String], prompts: [Prompt], preferences: UserPreferences) async throws {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let userId = session.user.id.uuidString

        let newUser = User(
            id: userId,
            name: name,
            age: age,
            gender: gender,
            bio: "",
            photos: photos,
            preferences: preferences,
            approximateLocation: nil,
            lastActive: Date(),
            prompts: prompts
        )

        try await supabase.database
            .from("users")
            .insert(newUser)
            .execute()

        currentUser = newUser
    }

    func updateUserLocation(coordinate: CLLocationCoordinate2D) async throws {
        guard let userId = currentUser?.id else { return }

        try await supabase.database
            .from("users")
            .update(["approximate_location": [coordinate.latitude, coordinate.longitude]])
            .eq("id", value: userId)
            .execute()

        currentUser?.approximateLocation = coordinate
    }

    func updateLastActive() async {
        guard let userId = currentUser?.id else { return }

        try? await supabase.database
            .from("users")
            .update(["last_active": Date()])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}
