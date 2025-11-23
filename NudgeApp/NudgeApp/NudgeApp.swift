import SwiftUI

@main
struct NudgeApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(locationService)
        }
    }
}
