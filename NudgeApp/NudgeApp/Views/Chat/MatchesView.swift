import SwiftUI

struct MatchesView: View {
    @StateObject private var chatService = ChatService.shared

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.white
                    .ignoresSafeArea()

                if chatService.conversations.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                        Image(systemName: "message")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(DesignSystem.Colors.mediumGray)

                        Text("No matches yet")
                            .font(DesignSystem.Typography.headerFont)
                            .foregroundColor(DesignSystem.Colors.black)

                        Text("Start liking profiles to get matches")
                            .font(DesignSystem.Typography.bodyFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(chatService.conversations) { conversation in
                            NavigationLink(destination: ChatView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await chatService.fetchConversations()
                }
            }
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.inlineSpacing) {
            // Profile Photo
            AsyncImage(url: URL(string: conversation.otherUser.primaryPhoto ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(DesignSystem.Colors.softGray)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.name)
                        .font(DesignSystem.Typography.bodyFontMedium)
                        .foregroundColor(DesignSystem.Colors.black)

                    if conversation.match.matchType == .nudge {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.accentBlue)
                    }

                    Spacer()

                    if let time = conversation.lastMessageTime {
                        Text(timeAgo(from: time))
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.Colors.mediumGray)
                    }
                }

                Text(conversation.lastMessagePreview)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.Colors.mediumGray)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.smallSpacing)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = hours / 24

        if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "now"
        }
    }
}

struct MatchesView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesView()
    }
}
