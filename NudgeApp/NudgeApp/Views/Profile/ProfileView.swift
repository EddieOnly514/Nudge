import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                if let user = authService.currentUser {
                    VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
                        // Photos
                        TabView {
                            ForEach(user.photos, id: \.self) { photoUrl in
                                AsyncImage(url: URL(string: photoUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(DesignSystem.Colors.softGray)
                                }
                                .frame(height: 500)
                                .clipped()
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 500)

                        // Basic Info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineSpacing) {
                            HStack {
                                Text(user.name)
                                    .font(DesignSystem.Typography.headerFont)
                                    .foregroundColor(DesignSystem.Colors.black)

                                Text("\(user.age)")
                                    .font(DesignSystem.Typography.bodyFont)
                                    .foregroundColor(DesignSystem.Colors.mediumGray)

                                Spacer()

                                Button(action: {
                                    // Edit profile
                                }) {
                                    Text("Edit")
                                        .font(DesignSystem.Typography.bodyFontMedium)
                                        .foregroundColor(DesignSystem.Colors.accentBlue)
                                }
                            }

                            Text(user.gender)
                                .font(DesignSystem.Typography.bodyFont)
                                .foregroundColor(DesignSystem.Colors.mediumGray)

                            if !user.bio.isEmpty {
                                Text(user.bio)
                                    .font(DesignSystem.Typography.bodyFont)
                                    .foregroundColor(DesignSystem.Colors.black)
                                    .padding(.top, DesignSystem.Spacing.smallSpacing)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

                        // Prompts
                        VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                            ForEach(user.prompts) { prompt in
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.smallSpacing) {
                                    Text(prompt.question)
                                        .font(DesignSystem.Typography.promptQuestionFont)
                                        .foregroundColor(DesignSystem.Colors.mediumGray)

                                    Text(prompt.answer)
                                        .font(DesignSystem.Typography.promptFont)
                                        .foregroundColor(DesignSystem.Colors.black)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.softGray)
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

                        // Settings Section
                        VStack(spacing: 0) {
                            SettingsRow(icon: "slider.horizontal.3", title: "Preferences", action: {})
                            Divider().padding(.leading, 50)

                            SettingsRow(icon: "bell", title: "Notifications", action: {})
                            Divider().padding(.leading, 50)

                            SettingsRow(icon: "lock.shield", title: "Privacy & Safety", action: {})
                            Divider().padding(.leading, 50)

                            SettingsRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                            Divider().padding(.leading, 50)

                            SettingsRow(icon: "doc.text", title: "Terms & Privacy", action: {})
                        }
                        .background(DesignSystem.Colors.white)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

                        // Sign Out
                        Button(action: {
                            Task {
                                try? await authService.signOut()
                            }
                        }) {
                            Text("Sign Out")
                                .font(DesignSystem.Typography.bodyFontMedium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DesignSystem.Colors.white)
                                .cornerRadius(DesignSystem.CornerRadius.card)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

                        // Version
                        Text("Nudge v1.0.0")
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                            .padding(.bottom, DesignSystem.Spacing.moduleSpacing)
                    }
                }
            }
            .background(DesignSystem.Colors.softGray)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.accentBlue)
                    .frame(width: 24)

                Text(title)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.Colors.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.mediumGray)
            }
            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.inlineSpacing)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthService.shared)
    }
}
