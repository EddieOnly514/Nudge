import React, { useState, useCallback, useEffect, useMemo, memo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { chatService, userService } from '../../services';

interface Message {
  id: string;
  text: string;
  senderId: string;
  timestamp: string;
}

// Memoized message bubble for performance
const MessageBubble = memo(({ item, isMine }: { item: Message; isMine: boolean }) => (
  <View style={[styles.messageBubble, isMine ? styles.myMessage : styles.theirMessage]}>
    <Text style={[styles.messageText, isMine && styles.myMessageText]}>
      {item.text}
    </Text>
    <Text style={[styles.messageTime, isMine && styles.myMessageTime]}>
      {new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
    </Text>
  </View>
));

function ChatScreen({ route, navigation }: any) {
  const { matchId, user } = route.params;
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  // Load messages and subscribe to realtime updates
  useEffect(() => {
    let subscription: any;

    const initialize = async () => {
      try {
        const authUser = await userService.getCurrentUser();
        if (authUser) {
          setCurrentUserId(authUser.id);
        } else {
          setCurrentUserId('me'); // For demo
        }

        // Load existing messages
        const existingMessages = await chatService.getMessages(matchId);
        setMessages(existingMessages.map((m: any) => ({
          id: m.id,
          text: m.text || m.content,
          senderId: m.sender_id,
          timestamp: m.timestamp,
        })));

        // Subscribe to new messages
        subscription = chatService.subscribeToMessages(matchId, (newMessage: any) => {
          setMessages((prev) => [...prev, {
            id: newMessage.id,
            text: newMessage.text || newMessage.content,
            senderId: newMessage.sender_id,
            timestamp: newMessage.timestamp,
          }]);
        });
      } catch (err) {
        console.error('Error loading messages:', err);
        // Load mock data for demo
        setMessages([
          {
            id: '1',
            text: 'Hey! How are you?',
            senderId: user.id,
            timestamp: new Date().toISOString(),
          },
          {
            id: '2',
            text: "I'm great, thanks! How about you?",
            senderId: 'me',
            timestamp: new Date().toISOString(),
          },
        ]);
      } finally {
        setLoading(false);
      }
    };

    initialize();

    // Cleanup subscription on unmount
    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, [matchId, user.id]);

  const sendMessage = useCallback(async () => {
    if (!message.trim() || sending) return;

    const messageText = message.trim();
    setMessage('');
    setSending(true);

    try {
      if (currentUserId && currentUserId !== 'me') {
        await chatService.sendMessage(matchId, currentUserId, messageText);
      } else {
        // Optimistic update for demo
        const newMessage: Message = {
          id: Date.now().toString(),
          text: messageText,
          senderId: 'me',
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, newMessage]);
      }
    } catch (err) {
      console.error('Error sending message:', err);
      // Restore message on error
      setMessage(messageText);
    } finally {
      setSending(false);
    }
  }, [message, matchId, currentUserId, sending]);

  const renderMessage = useCallback(({ item }: { item: Message }) => {
    const isMine = item.senderId === 'me' || item.senderId === currentUserId;
    return <MessageBubble item={item} isMine={isMine} />;
  }, [currentUserId]);

  const keyExtractor = useCallback((item: Message) => item.id, []);

  // Memoized reversed messages for FlatList
  const reversedMessages = useMemo(() =>
    [...messages].reverse(),
    [messages]
  );

  const handleGoBack = useCallback(() => {
    navigation.goBack();
  }, [navigation]);

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={handleGoBack}>
            <Ionicons name="arrow-back" size={24} color="#333" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>
            {user.name}, {user.age}
          </Text>
          <View style={{ width: 24 }} />
        </View>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#FF6B9D" />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={handleGoBack}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>
          {user.name}, {user.age}
        </Text>
        <View style={{ width: 24 }} />
      </View>

      <KeyboardAvoidingView
        style={styles.chatContainer}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={90}
      >
        <FlatList
          data={reversedMessages}
          renderItem={renderMessage}
          keyExtractor={keyExtractor}
          contentContainerStyle={styles.messagesList}
          inverted={true}
          removeClippedSubviews={true}
          maxToRenderPerBatch={15}
          initialNumToRender={20}
          windowSize={10}
        />

        <View style={styles.inputContainer}>
          <TextInput
            style={styles.input}
            placeholder="Type a message..."
            value={message}
            onChangeText={setMessage}
            multiline
            maxLength={1000}
          />
          <TouchableOpacity
            style={[styles.sendButton, (!message.trim() || sending) && styles.sendButtonDisabled]}
            onPress={sendMessage}
            disabled={!message.trim() || sending}
          >
            {sending ? (
              <ActivityIndicator size="small" color="#FFF" />
            ) : (
              <Ionicons name="send" size={20} color="#FFF" />
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

export default memo(ChatScreen);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#EEE',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  chatContainer: {
    flex: 1,
  },
  messagesList: {
    padding: 16,
    gap: 8,
  },
  messageBubble: {
    maxWidth: '75%',
    padding: 12,
    borderRadius: 16,
    marginBottom: 4,
  },
  myMessage: {
    alignSelf: 'flex-end',
    backgroundColor: '#FF6B9D',
  },
  theirMessage: {
    alignSelf: 'flex-start',
    backgroundColor: '#FFF',
  },
  messageText: {
    fontSize: 16,
    color: '#333',
  },
  myMessageText: {
    color: '#FFF',
  },
  messageTime: {
    fontSize: 10,
    color: '#999',
    marginTop: 4,
    alignSelf: 'flex-end',
  },
  myMessageTime: {
    color: 'rgba(255,255,255,0.7)',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  inputContainer: {
    flexDirection: 'row',
    padding: 16,
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderTopColor: '#EEE',
    alignItems: 'flex-end',
  },
  input: {
    flex: 1,
    backgroundColor: '#F8F9FA',
    borderRadius: 24,
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginRight: 8,
    maxHeight: 100,
    fontSize: 16,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FF6B9D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: '#CCC',
  },
});
