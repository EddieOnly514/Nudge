import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Discover")
                }
                .tag(0)

            MatchesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Matches")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(DesignSystem.Colors.accentBlue)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthService.shared)
            .environmentObject(LocationService.shared)
    }
}
