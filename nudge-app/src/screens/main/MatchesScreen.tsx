import React, { useState, useEffect, useCallback, memo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  SafeAreaView,
  Image,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { matchingService, userService } from '../../services';

interface Conversation {
  id: string;
  otherUser: {
    id: string;
    name: string;
    age: number;
    photos: string[];
  };
  lastMessage?: string;
  lastMessageTime?: string;
  unread?: boolean;
}

// Memoized conversation item for FlatList performance
const ConversationItem = memo(({
  item,
  onPress
}: {
  item: Conversation;
  onPress: () => void;
}) => (
  <TouchableOpacity style={styles.conversationCard} onPress={onPress}>
    <Image
      source={{ uri: item.otherUser.photos[0] || 'https://via.placeholder.com/100' }}
      style={styles.avatar}
    />
    <View style={styles.conversationInfo}>
      <View style={styles.conversationHeader}>
        <Text style={styles.userName}>
          {item.otherUser.name}, {item.otherUser.age}
        </Text>
        {item.lastMessageTime && (
          <Text style={styles.timestamp}>{item.lastMessageTime}</Text>
        )}
      </View>
      <Text style={[styles.lastMessage, item.unread && styles.unreadMessage]}>
        {item.lastMessage || 'Say hello! 👋'}
      </Text>
    </View>
    {item.unread && <View style={styles.unreadDot} />}
  </TouchableOpacity>
));

function MatchesScreen({ navigation }: any) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadMatches();
  }, []);

  const loadMatches = useCallback(async () => {
    try {
      const currentUser = await userService.getCurrentUser();
      if (currentUser) {
        const matches = await matchingService.getMatches(currentUser.id);

        // Transform matches to conversations format
        const convs: Conversation[] = matches.map((match: any) => ({
          id: match.id,
          otherUser: {
            id: match.user_1 === currentUser.id ? match.user_2 : match.user_1,
            name: 'Match',
            age: 25,
            photos: ['https://via.placeholder.com/100'],
          },
        }));

        setConversations(convs);
      } else {
        // Mock data for demo
        setConversations([
          {
            id: '1',
            otherUser: {
              id: 'u1',
              name: 'Sarah',
              age: 25,
              photos: ['https://via.placeholder.com/100'],
            },
            lastMessage: 'Hey! How are you?',
            lastMessageTime: '2m ago',
            unread: true,
          },
          {
            id: '2',
            otherUser: {
              id: 'u2',
              name: 'Emma',
              age: 27,
              photos: ['https://via.placeholder.com/100'],
            },
            lastMessage: 'That sounds great!',
            lastMessageTime: '1h ago',
            unread: false,
          },
        ]);
      }
    } catch (err) {
      console.error('Error loading matches:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  const handleRefresh = useCallback(() => {
    setRefreshing(true);
    loadMatches();
  }, [loadMatches]);

  const handleConversationPress = useCallback((item: Conversation) => {
    navigation.navigate('Chat', { matchId: item.id, user: item.otherUser });
  }, [navigation]);

  const renderConversation = useCallback(({ item }: { item: Conversation }) => (
    <ConversationItem
      item={item}
      onPress={() => handleConversationPress(item)}
    />
  ), [handleConversationPress]);

  const keyExtractor = useCallback((item: Conversation) => item.id, []);

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Messages</Text>
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
        <Text style={styles.title}>Messages</Text>
      </View>

      {conversations.length > 0 ? (
        <FlatList
          data={conversations}
          renderItem={renderConversation}
          keyExtractor={keyExtractor}
          contentContainerStyle={styles.list}
          removeClippedSubviews={true}
          maxToRenderPerBatch={10}
          initialNumToRender={10}
          windowSize={5}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={handleRefresh}
              tintColor="#FF6B9D"
            />
          }
        />
      ) : (
        <View style={styles.emptyContainer}>
          <Ionicons name="chatbubbles-outline" size={80} color="#CCC" />
          <Text style={styles.emptyTitle}>No matches yet</Text>
          <Text style={styles.emptySubtitle}>
            Start swiping to find your matches!
          </Text>
        </View>
      )}
    </SafeAreaView>
  );
}

export default memo(MatchesScreen);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    padding: 24,
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#EEE',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
  },
  list: {
    padding: 16,
    gap: 12,
  },
  conversationCard: {
    flexDirection: 'row',
    backgroundColor: '#FFF',
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    marginRight: 12,
  },
  conversationInfo: {
    flex: 1,
  },
  conversationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  userName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  timestamp: {
    fontSize: 12,
    color: '#999',
  },
  lastMessage: {
    fontSize: 14,
    color: '#666',
  },
  unreadMessage: {
    fontWeight: '600',
    color: '#333',
  },
  unreadDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#FF6B9D',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
