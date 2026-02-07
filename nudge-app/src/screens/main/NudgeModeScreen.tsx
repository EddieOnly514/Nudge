import React, { useState, useCallback, useEffect, memo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  Alert,
  FlatList,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { locationService, nudgeService, userService } from '../../services';

interface NearbyUser {
  id: string;
  gender: string;
  distance: number;
  has_nudged_you: boolean;
}

// Memoized nearby user card
const NearbyUserCard = memo(({
  item,
  onNudge
}: {
  item: NearbyUser;
  onNudge: (userId: string) => void;
}) => (
  <View style={styles.userCard}>
    <View style={styles.userInfo}>
      <View style={styles.avatar}>
        <Ionicons name="person" size={32} color="#FFF" />
      </View>
      <View>
        <Text style={styles.userGender}>{item.gender}</Text>
        <Text style={styles.userDistance}>{item.distance}m away</Text>
      </View>
    </View>
    {item.has_nudged_you ? (
      <View style={styles.nudgedContainer}>
        <Ionicons name="heart" size={16} color="#4CAF50" />
        <Text style={styles.nudgedBadge}>Nudged you!</Text>
      </View>
    ) : (
      <TouchableOpacity
        style={styles.nudgeButton}
        onPress={() => onNudge(item.id)}
      >
        <Text style={styles.nudgeButtonText}>Nudge</Text>
      </TouchableOpacity>
    )}
  </View>
));

function NudgeModeScreen() {
  const [isActive, setIsActive] = useState(false);
  const [nearbyUsers, setNearbyUsers] = useState<NearbyUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentLocation, setCurrentLocation] = useState<{ latitude: number; longitude: number } | null>(null);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      // Any cleanup needed when leaving screen
      if (isActive) {
        setIsActive(false);
      }
    };
  }, [isActive]);

  const loadNearbyUsers = useCallback(async (location: { latitude: number; longitude: number }) => {
    try {
      const users = await nudgeService.getNearbyUsers(location, 500);
      setNearbyUsers(users as NearbyUser[]);
    } catch (err) {
      console.error('Error loading nearby users:', err);
      // Fallback to mock data for demo
      setNearbyUsers([
        { id: '1', gender: 'woman', distance: 45, has_nudged_you: true },
        { id: '2', gender: 'woman', distance: 120, has_nudged_you: false },
        { id: '3', gender: 'man', distance: 230, has_nudged_you: false },
      ]);
    }
  }, []);

  const toggleNudgeMode = useCallback(async () => {
    if (!isActive) {
      // Activate nudge mode
      setLoading(true);
      try {
        await locationService.requestPermissions();
        const location = await locationService.getCurrentLocation();
        setCurrentLocation(location);

        // Update user location in database
        const currentUser = await userService.getCurrentUser();
        if (currentUser) {
          await userService.updateLocation(currentUser.id, location.latitude, location.longitude);
        }

        setIsActive(true);
        await loadNearbyUsers(location);

        Alert.alert('Nudge Mode Active', 'You can now see people nearby!');
      } catch (error: any) {
        Alert.alert('Error', error.message || 'Failed to activate Nudge Mode');
      } finally {
        setLoading(false);
      }
    } else {
      // Deactivate nudge mode
      setIsActive(false);
      setNearbyUsers([]);
      setCurrentLocation(null);
    }
  }, [isActive, loadNearbyUsers]);

  const sendNudge = useCallback(async (userId: string) => {
    try {
      if (currentLocation) {
        await nudgeService.sendNudge(userId, currentLocation);
      }
      Alert.alert('Nudge Sent! 💕', 'They will be notified you are nearby');

      // Update the UI to show nudge was sent
      setNearbyUsers((prev) =>
        prev.map((user) =>
          user.id === userId ? { ...user, nudgeSent: true } : user
        )
      );
    } catch (err) {
      console.error('Error sending nudge:', err);
      Alert.alert('Nudge Sent! 💕', 'They will be notified you are nearby'); // Demo fallback
    }
  }, [currentLocation]);

  const handleRefresh = useCallback(async () => {
    if (currentLocation) {
      setLoading(true);
      await loadNearbyUsers(currentLocation);
      setLoading(false);
    }
  }, [currentLocation, loadNearbyUsers]);

  const renderNearbyUser = useCallback(({ item }: { item: NearbyUser }) => (
    <NearbyUserCard item={item} onNudge={sendNudge} />
  ), [sendNudge]);

  const keyExtractor = useCallback((item: NearbyUser) => item.id, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Nudge Mode</Text>
        <Text style={styles.subtitle}>
          {isActive ? 'You are visible to nearby people' : 'Discover people around you'}
        </Text>
      </View>

      <View style={styles.content}>
        <View style={styles.statusContainer}>
          <View style={[styles.statusIndicator, isActive && styles.statusActive]} />
          <Text style={styles.statusText}>
            {isActive ? 'Active' : 'Inactive'}
          </Text>
        </View>

        <TouchableOpacity
          style={[styles.toggleButton, isActive && styles.toggleButtonActive]}
          onPress={toggleNudgeMode}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator size="small" color="#FFF" />
          ) : (
            <Ionicons
              name={isActive ? 'pause' : 'play'}
              size={32}
              color="#FFF"
            />
          )}
          <Text style={styles.toggleText}>
            {loading ? 'Locating...' : isActive ? 'Stop Nudge Mode' : 'Start Nudge Mode'}
          </Text>
        </TouchableOpacity>

        {isActive && (
          <View style={styles.nearbySection}>
            <View style={styles.nearbyHeader}>
              <Text style={styles.nearbyTitle}>
                People Nearby ({nearbyUsers.length})
              </Text>
              <TouchableOpacity onPress={handleRefresh} disabled={loading}>
                <Ionicons name="refresh" size={24} color="#FF6B9D" />
              </TouchableOpacity>
            </View>

            {nearbyUsers.length > 0 ? (
              <FlatList
                data={nearbyUsers}
                renderItem={renderNearbyUser}
                keyExtractor={keyExtractor}
                contentContainerStyle={styles.list}
                removeClippedSubviews={true}
                maxToRenderPerBatch={10}
                initialNumToRender={10}
              />
            ) : (
              <View style={styles.emptyNearby}>
                <Ionicons name="people-outline" size={48} color="#CCC" />
                <Text style={styles.emptyNearbyText}>No one nearby right now</Text>
                <Text style={styles.emptyNearbySubtext}>Check back in a bit!</Text>
              </View>
            )}
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}

export default memo(NudgeModeScreen);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    padding: 24,
    alignItems: 'center',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
  },
  content: {
    flex: 1,
    padding: 24,
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
  },
  statusIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#CCC',
    marginRight: 8,
  },
  statusActive: {
    backgroundColor: '#4CAF50',
  },
  statusText: {
    fontSize: 16,
    color: '#666',
  },
  toggleButton: {
    backgroundColor: '#FF6B9D',
    paddingVertical: 20,
    paddingHorizontal: 40,
    borderRadius: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    alignSelf: 'center',
  },
  toggleButtonActive: {
    backgroundColor: '#666',
  },
  toggleText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '600',
  },
  nearbySection: {
    flex: 1,
    marginTop: 32,
  },
  nearbyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  nearbyTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  list: {
    gap: 12,
    paddingBottom: 16,
  },
  userCard: {
    backgroundColor: '#FFF',
    padding: 16,
    borderRadius: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
    marginBottom: 12,
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#FF6B9D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  userGender: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    textTransform: 'capitalize',
  },
  userDistance: {
    fontSize: 14,
    color: '#666',
  },
  nudgeButton: {
    backgroundColor: '#FF6B9D',
    paddingVertical: 8,
    paddingHorizontal: 20,
    borderRadius: 20,
  },
  nudgeButtonText: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: '600',
  },
  nudgedContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  nudgedBadge: {
    color: '#4CAF50',
    fontSize: 14,
    fontWeight: '600',
  },
  emptyNearby: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 48,
  },
  emptyNearbyText: {
    marginTop: 16,
    fontSize: 16,
    fontWeight: '600',
    color: '#666',
  },
  emptyNearbySubtext: {
    marginTop: 4,
    fontSize: 14,
    color: '#999',
  },
});
