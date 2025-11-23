import SwiftUI

struct NudgeModeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var nudgeModeService = NudgeModeService.shared
    @StateObject private var locationService = LocationService.shared

    @State private var isActive = false
    @State private var showMatchReveal = false
    @State private var revealedMatch: Match?

    var body: some View {
        ZStack {
            DesignSystem.Colors.white
                .ignoresSafeArea()

            if !isActive {
                // Entry Screen
                VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.lightBlueBackground)
                            .frame(width: 200, height: 200)

                        Image(systemName: "location.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(DesignSystem.Colors.accentBlue)
                    }

                    VStack(spacing: DesignSystem.Spacing.smallSpacing) {
                        Text("Enter Nudge Mode")
                            .font(DesignSystem.Typography.headerFont)
                            .foregroundColor(DesignSystem.Colors.black)

                        Text("Find people within 20-50m of you\nPrecise location used only while active")
                            .font(DesignSystem.Typography.bodyFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    Button(action: {
                        activateNudgeMode()
                    }) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Activate")
                                .font(DesignSystem.Typography.buttonFont)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignSystem.Colors.accentBlue)
                        .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(DesignSystem.Typography.bodyFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                    }
                    .padding(.bottom, DesignSystem.Spacing.moduleSpacing)
                }
            } else {
                // Active Nudge Mode
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            deactivateNudgeMode()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14))
                                Text("Leave")
                                    .font(DesignSystem.Typography.captionFont)
                            }
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)

                            Text("Nudge Mode · \(Int(nudgeModeService.currentRadius))m")
                                .font(DesignSystem.Typography.bodyFontMedium)
                                .foregroundColor(DesignSystem.Colors.accentBlue)
                        }

                        Spacer()

                        // Radius adjustment
                        Menu {
                            Button("20m") { nudgeModeService.setRadius(20) }
                            Button("30m") { nudgeModeService.setRadius(30) }
                            Button("50m") { nudgeModeService.setRadius(50) }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(DesignSystem.Colors.mediumGray)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.vertical, DesignSystem.Spacing.inlineSpacing)

                    Divider()

                    // Nearby Users Grid
                    if nudgeModeService.nearbyUsers.isEmpty {
                        Spacer()
                        VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.bottom, DesignSystem.Spacing.smallSpacing)

                            Text("Searching nearby...")
                                .font(DesignSystem.Typography.bodyFont)
                                .foregroundColor(DesignSystem.Colors.mediumGray)

                            Text("\(nudgeModeService.nearbyUsers.count) people found")
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.Colors.mediumGray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                spacing: DesignSystem.Spacing.inlineSpacing
                            ) {
                                ForEach(nudgeModeService.nearbyUsers) { anonymousUser in
                                    NudgeSilhouetteCard(
                                        anonymousUser: anonymousUser,
                                        onNudge: {
                                            sendNudge(to: anonymousUser)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                            .padding(.vertical, DesignSystem.Spacing.inlineSpacing)
                        }
                    }

                    // Received Nudges Banner
                    if !nudgeModeService.receivedNudges.isEmpty {
                        VStack(spacing: 0) {
                            Divider()

                            Button(action: {
                                // Show received nudges
                            }) {
                                HStack {
                                    Image(systemName: "hand.wave.fill")
                                        .foregroundColor(DesignSystem.Colors.accentBlue)

                                    Text("\(nudgeModeService.receivedNudges.count) people nudged you")
                                        .font(DesignSystem.Typography.bodyFontMedium)
                                        .foregroundColor(DesignSystem.Colors.black)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DesignSystem.Colors.mediumGray)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                                .padding(.vertical, DesignSystem.Spacing.inlineSpacing)
                                .background(DesignSystem.Colors.lightBlueBackground)
                            }
                        }
                    }
                }
            }

            // Match Reveal Overlay
            if showMatchReveal, let match = revealedMatch {
                MatchRevealView(match: match, onDismiss: {
                    showMatchReveal = false
                    revealedMatch = nil
                })
            }
        }
    }

    private func activateNudgeMode() {
        Task {
            await nudgeModeService.activateNudgeMode()
            withAnimation {
                isActive = true
            }
        }
    }

    private func deactivateNudgeMode() {
        Task {
            await nudgeModeService.deactivateNudgeMode()
            dismiss()
        }
    }

    private func sendNudge(to anonymousUser: AnonymousNudge) {
        Task {
            try? await nudgeModeService.sendNudge(to: anonymousUser.id)
            // Check for match and show reveal if mutual
        }
    }
}

// MARK: - Silhouette Card

struct NudgeSilhouetteCard: View {
    let anonymousUser: AnonymousNudge
    let onNudge: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.smallSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.softGray)
                    .frame(height: 150)

                VStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(DesignSystem.Colors.mediumGray)

                    Text("\(Int(anonymousUser.distance))m")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.Colors.mediumGray)
                }
            }

            Button(action: onNudge) {
                Text(anonymousUser.hasNudgedYou ? "Nudge Back" : "Nudge")
                    .font(DesignSystem.Typography.captionFont.weight(.semibold))
                    .foregroundColor(anonymousUser.hasNudgedYou ? .white : DesignSystem.Colors.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(anonymousUser.hasNudgedYou ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DesignSystem.Colors.accentBlue, lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Match Reveal

struct MatchRevealView: View {
    let match: Match
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.moduleSpacing) {
                if showContent {
                    Image(systemName: "sparkles")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(DesignSystem.Colors.accentBlue)

                    Text("It's a Match!")
                        .font(DesignSystem.Typography.headerFontLarge)
                        .foregroundColor(.white)

                    Text("You and [Name] are nearby")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(.white.opacity(0.8))

                    // Photos would go here

                    Button(action: onDismiss) {
                        Text("Start Chat")
                            .font(DesignSystem.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(DesignSystem.Colors.accentBlue)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

struct NudgeModeView_Previews: PreviewProvider {
    static var previews: some View {
        NudgeModeView()
    }
}
