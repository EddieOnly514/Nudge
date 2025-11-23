import SwiftUI

struct HomeView: View {
    @StateObject private var matchingService = MatchingService.shared
    @State private var showNudgeMode = false
    @State private var currentCardIndex = 0

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Nudge Mode button
                    HStack {
                        Text("Nudge")
                            .font(DesignSystem.Typography.headerFont)
                            .foregroundColor(DesignSystem.Colors.black)

                        Spacer()

                        Button(action: {
                            showNudgeMode = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                Text("Nudge Mode")
                                    .font(DesignSystem.Typography.captionFont)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DesignSystem.Colors.accentBlue)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.top, DesignSystem.Spacing.smallSpacing)

                    // Context Banner
                    if let suggestion = getSuggestion() {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(DesignSystem.Colors.accentBlue)
                            Text(suggestion)
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.Colors.mediumGray)
                            Spacer()
                        }
                        .padding()
                        .background(DesignSystem.Colors.lightBlueBackground)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                        .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                        .padding(.vertical, DesignSystem.Spacing.smallSpacing)
                    }

                    // Feed
                    if matchingService.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if currentCardIndex < matchingService.feedUsers.count {
                        ScrollView {
                            DatingCardView(
                                user: matchingService.feedUsers[currentCardIndex],
                                onLike: { handleLike() },
                                onPass: { handlePass() }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                        }
                    } else {
                        Spacer()
                        VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(DesignSystem.Colors.mediumGray)

                            Text("You're all caught up")
                                .font(DesignSystem.Typography.headerFont)
                                .foregroundColor(DesignSystem.Colors.black)

                            Text("Check back later for more matches")
                                .font(DesignSystem.Typography.bodyFont)
                                .foregroundColor(DesignSystem.Colors.mediumGray)

                            Button(action: {
                                Task {
                                    await matchingService.fetchFeed()
                                    currentCardIndex = 0
                                }
                            }) {
                                Text("Refresh")
                                    .font(DesignSystem.Typography.buttonFont)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(DesignSystem.Colors.accentBlue)
                                    .cornerRadius(DesignSystem.CornerRadius.button)
                            }
                            .padding(.top, DesignSystem.Spacing.inlineSpacing)
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await matchingService.fetchFeed()
                }
            }
            .fullScreenCover(isPresented: $showNudgeMode) {
                NudgeModeView()
            }
        }
    }

    private func getSuggestion() -> String? {
        // Simplified - in production, use AI service
        return "Smart Suggestions Near You"
    }

    private func handleLike() {
        guard currentCardIndex < matchingService.feedUsers.count else { return }
        let user = matchingService.feedUsers[currentCardIndex]

        Task {
            try? await matchingService.likeUser(user)
            withAnimation {
                currentCardIndex += 1
            }
        }
    }

    private func handlePass() {
        guard currentCardIndex < matchingService.feedUsers.count else { return }
        let user = matchingService.feedUsers[currentCardIndex]

        Task {
            try? await matchingService.passUser(user)
            withAnimation {
                currentCardIndex += 1
            }
        }
    }
}

// MARK: - Dating Card View

struct DatingCardView: View {
    let user: User
    let onLike: () -> Void
    let onPass: () -> Void

    @State private var currentPhotoIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photos
            TabView(selection: $currentPhotoIndex) {
                ForEach(user.photos.indices, id: \.self) { index in
                    AsyncImage(url: URL(string: user.photos[index])) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(DesignSystem.Colors.softGray)
                    }
                    .frame(height: 500)
                    .clipped()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 500)
            .cornerRadius(DesignSystem.CornerRadius.card, corners: [.topLeft, .topRight])

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineSpacing) {
                HStack {
                    Text(user.name)
                        .font(DesignSystem.Typography.headerFont)
                        .foregroundColor(DesignSystem.Colors.black)

                    Text("\(user.age)")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.Colors.mediumGray)

                    Spacer()
                }

                // Prompts
                ForEach(user.prompts) { prompt in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tightSpacing) {
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
            .padding(DesignSystem.Spacing.inlineSpacing)
            .background(DesignSystem.Colors.white)
            .cornerRadius(DesignSystem.CornerRadius.card, corners: [.bottomLeft, .bottomRight])

            // Action Buttons
            HStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                Button(action: onPass) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.mediumGray)
                        .frame(width: 60, height: 60)
                        .background(DesignSystem.Colors.white)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.mediumGray, lineWidth: 2)
                        )
                        .clipShape(Circle())
                }

                Spacer()

                Button(action: onLike) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(DesignSystem.Colors.accentBlue)
                        .clipShape(Circle())
                }
            }
            .padding(.top, DesignSystem.Spacing.inlineSpacing)
        }
        .background(DesignSystem.Colors.white)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
}

// Extension for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
