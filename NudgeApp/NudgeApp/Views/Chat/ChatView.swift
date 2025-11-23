import SwiftUI

struct ChatView: View {
    let conversation: Conversation

    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject private var authService: AuthService

    @State private var messageText = ""
    @State private var showSuggestions = false
    @State private var suggestions: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authService.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.vertical, DesignSystem.Spacing.inlineSpacing)
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // AI Suggestions
            if showSuggestions && !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.smallSpacing) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                messageText = suggestion
                                showSuggestions = false
                            }) {
                                Text(suggestion)
                                    .font(DesignSystem.Typography.captionFont)
                                    .foregroundColor(DesignSystem.Colors.accentBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(DesignSystem.Colors.lightBlueBackground)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
                    .padding(.vertical, DesignSystem.Spacing.smallSpacing)
                }
                .background(DesignSystem.Colors.softGray)
            }

            // Input Bar
            HStack(spacing: DesignSystem.Spacing.inlineSpacing) {
                Button(action: {
                    loadSuggestions()
                }) {
                    Image(systemName: showSuggestions ? "sparkles.square.fill" : "sparkles")
                        .foregroundColor(DesignSystem.Colors.accentBlue)
                        .font(.system(size: 24))
                }

                TextField("Message", text: $messageText)
                    .font(DesignSystem.Typography.bodyFont)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.softGray)
                    .cornerRadius(20)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(messageText.isEmpty ? DesignSystem.Colors.mediumGray : DesignSystem.Colors.accentBlue)
                        .font(.system(size: 32))
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, DesignSystem.Spacing.horizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.smallSpacing)
            .background(DesignSystem.Colors.white)
        }
        .navigationTitle(conversation.otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        blockUser()
                    }) {
                        Label("Block", systemImage: "hand.raised.fill")
                    }

                    Button(role: .destructive, action: {
                        reportUser()
                    }) {
                        Label("Report", systemImage: "exclamationmark.triangle.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DesignSystem.Colors.black)
                }
            }
        }
        .onAppear {
            chatService.subscribeToConversation(conversation.id)
        }
        .onDisappear {
            chatService.unsubscribeFromConversation()
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let text = messageText
        messageText = ""
        showSuggestions = false

        Task {
            try? await chatService.sendMessage(text, in: conversation.id)
        }
    }

    private func loadSuggestions() {
        showSuggestions.toggle()

        if showSuggestions && suggestions.isEmpty {
            Task {
                suggestions = await chatService.getMessageSuggestions(for: conversation.id)
            }
        }
    }

    private func blockUser() {
        Task {
            try? await chatService.blockUser(conversation.otherUser.id)
        }
    }

    private func reportUser() {
        Task {
            try? await chatService.reportUser(conversation.otherUser.id, reason: "Inappropriate behavior")
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(isFromCurrentUser ? .white : DesignSystem.Colors.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.softGray)
                    .cornerRadius(20, corners: isFromCurrentUser ?
                        [.topLeft, .topRight, .bottomLeft] :
                        [.topLeft, .topRight, .bottomRight]
                    )

                Text(formatTime(message.timestamp))
                    .font(DesignSystem.Typography.smallFont)
                    .foregroundColor(DesignSystem.Colors.mediumGray)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)

            if !isFromCurrentUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(conversation: Conversation(
                id: "1",
                match: Match(id: "1", user1Id: "1", user2Id: "2", createdAt: Date(), expiredAt: nil, matchType: .regular),
                otherUser: User(id: "2", name: "Alex", age: 25, gender: "Woman", bio: "", photos: [], preferences: UserPreferences(minAge: 18, maxAge: 35, maxDistance: 50, interestedIn: ["Man"]), approximateLocation: nil, lastActive: Date(), prompts: []),
                messages: [],
                lastMessage: nil
            ))
        }
        .environmentObject(AuthService.shared)
    }
}
