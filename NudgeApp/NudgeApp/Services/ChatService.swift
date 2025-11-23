import Foundation
import Supabase
import Combine

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published var conversations: [Conversation] = []
    @Published var activeConversation: Conversation?

    private let supabase = SupabaseClient.shared
    private let authService = AuthService.shared
    private let aiService = AIService.shared

    private var realtimeChannel: RealtimeChannel?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Fetch Conversations

    func fetchConversations() async {
        guard let currentUser = authService.currentUser else { return }

        do {
            // Fetch matches
            let matches: [Match] = try await supabase.database
                .from("matches")
                .select()
                .or("user_1.eq.\(currentUser.id),user_2.eq.\(currentUser.id)")
                .order("created_at", ascending: false)
                .execute()
                .value

            // Build conversations
            var conversationList: [Conversation] = []

            for match in matches where !match.isExpired {
                let otherUserId = match.otherUserId(currentUserId: currentUser.id)

                // Fetch other user
                let otherUser: User = try await supabase.database
                    .from("users")
                    .select()
                    .eq("id", value: otherUserId)
                    .single()
                    .execute()
                    .value

                // Fetch messages
                let messages: [ChatMessage] = try await supabase.database
                    .from("chat_messages")
                    .select()
                    .eq("match_id", value: match.id)
                    .order("timestamp", ascending: true)
                    .execute()
                    .value

                let conversation = Conversation(
                    id: match.id,
                    match: match,
                    otherUser: otherUser,
                    messages: messages,
                    lastMessage: messages.last
                )

                conversationList.append(conversation)
            }

            // Sort by last message time
            conversationList.sort { conv1, conv2 in
                (conv1.lastMessageTime ?? Date.distantPast) > (conv2.lastMessageTime ?? Date.distantPast)
            }

            conversations = conversationList

        } catch {
            print("Error fetching conversations: \(error)")
        }
    }

    // MARK: - Send Message

    func sendMessage(_ text: String, in conversationId: String) async throws {
        guard let currentUser = authService.currentUser else { return }

        // AI safety filter
        let isFlagged = try await aiService.moderateMessage(text)

        let message = ChatMessage(
            id: UUID().uuidString,
            matchId: conversationId,
            senderId: currentUser.id,
            text: text,
            timestamp: Date(),
            aiFlagged: isFlagged
        )

        try await supabase.database
            .from("chat_messages")
            .insert(message)
            .execute()

        // Track interaction for AI
        if let conversation = conversations.first(where: { $0.id == conversationId }) {
            await aiService.trackInteraction(
                userId: currentUser.id,
                targetUserId: conversation.otherUser.id,
                type: .messaged
            )
        }

        // Update local state
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].messages.append(message)
            conversations[index].lastMessage = message

            // Move to top
            let conversation = conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
        }
    }

    // MARK: - Realtime Messaging

    func subscribeToConversation(_ conversationId: String) {
        unsubscribeFromConversation()

        realtimeChannel = supabase.realtime.channel("messages:\(conversationId)")

        realtimeChannel?.on(.insert) { [weak self] message in
            Task { @MainActor in
                self?.handleNewMessage(message)
            }
        }

        realtimeChannel?.subscribe()
    }

    func unsubscribeFromConversation() {
        realtimeChannel?.unsubscribe()
        realtimeChannel = nil
    }

    private func handleNewMessage(_ payload: RealtimeMessage) {
        guard let messageData = payload.payload["record"] as? [String: Any],
              let messageJson = try? JSONSerialization.data(withJSONObject: messageData),
              let message = try? JSONDecoder().decode(ChatMessage.self, from: messageJson) else {
            return
        }

        // Update conversation
        if let index = conversations.firstIndex(where: { $0.id == message.matchId }) {
            conversations[index].messages.append(message)
            conversations[index].lastMessage = message

            // Move to top
            let conversation = conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
        }
    }

    // MARK: - AI Assistance

    func getMessageSuggestions(for conversationId: String) async -> [String] {
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else {
            return []
        }

        return await aiService.generateMessageSuggestions(
            for: conversation.match,
            conversation: conversation.messages
        )
    }

    func getFirstMessageIdea(for conversationId: String) async -> String? {
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else {
            return nil
        }

        return await aiService.generateFirstMessageIdea(for: conversation.otherUser)
    }

    // MARK: - Safety

    func blockUser(_ userId: String) async throws {
        guard let currentUser = authService.currentUser else { return }

        try await supabase.database
            .from("blocked_users")
            .insert([
                "user_id": currentUser.id,
                "blocked_user_id": userId,
                "timestamp": Date()
            ])
            .execute()

        // Remove conversations with blocked user
        conversations.removeAll { $0.otherUser.id == userId }
    }

    func reportUser(_ userId: String, reason: String) async throws {
        guard let currentUser = authService.currentUser else { return }

        try await supabase.database
            .from("reports")
            .insert([
                "reporter_id": currentUser.id,
                "reported_user_id": userId,
                "reason": reason,
                "timestamp": Date()
            ])
            .execute()
    }
}
