import React, { useState, useCallback, useEffect, memo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  SafeAreaView,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { matchingService, userService } from '../../services';

const { height } = Dimensions.get('window');

interface Profile {
  id: string;
  name: string;
  age: number;
  bio: string;
  photos: string[];
  distance?: string;
}

// Memoized profile card for performance
const ProfileCard = memo(({ profile }: { profile: Profile }) => (
  <View style={styles.card}>
    <Image
      source={{ uri: profile.photos[0] || 'https://via.placeholder.com/400' }}
      style={styles.image}
      resizeMode="cover"
    />
    <View style={styles.infoContainer}>
      <View>
        <Text style={styles.name}>
          {profile.name}, {profile.age}
        </Text>
        {profile.distance && (
          <Text style={styles.distance}>{profile.distance}</Text>
        )}
        <Text style={styles.bio}>{profile.bio}</Text>
      </View>
    </View>
  </View>
));

function HomeScreen() {
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load profiles on mount
  useEffect(() => {
    loadProfiles();
  }, []);

  const loadProfiles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const currentUser = await userService.getCurrentUser();
      if (currentUser) {
        const matches = await matchingService.getPotentialMatches(
          currentUser.id,
          currentUser.preferences || { min_age: 18, max_age: 50, interested_in: ['woman', 'man'] }
        );
        setProfiles(matches as Profile[]);
      } else {
        // Fallback to mock data for demo
        setProfiles([
          {
            id: '1',
            name: 'Sarah',
            age: 25,
            bio: 'Coffee enthusiast and adventure seeker',
            photos: ['https://via.placeholder.com/400'],
            distance: '2 km away',
          },
          {
            id: '2',
            name: 'Emma',
            age: 27,
            bio: 'Artist and dog lover',
            photos: ['https://via.placeholder.com/400'],
            distance: '5 km away',
          },
        ]);
      }
    } catch (err) {
      console.error('Error loading profiles:', err);
      setError('Failed to load profiles');
    } finally {
      setLoading(false);
    }
  }, []);

  const currentProfile = profiles[currentIndex];

  const handleLike = useCallback(async () => {
    if (!currentProfile) return;

    try {
      const currentUser = await userService.getCurrentUser();
      if (currentUser) {
        const match = await matchingService.likeUser(currentUser.id, currentProfile.id);
        if (match) {
          console.log('It\'s a match!', match);
        }
      }
    } catch (err) {
      console.error('Error liking profile:', err);
    }

    setCurrentIndex((prev) => (prev + 1) % profiles.length);
  }, [currentProfile, profiles.length]);

  const handlePass = useCallback(async () => {
    if (!currentProfile) return;

    try {
      const currentUser = await userService.getCurrentUser();
      if (currentUser) {
        await matchingService.passUser(currentUser.id, currentProfile.id);
      }
    } catch (err) {
      console.error('Error passing profile:', err);
    }

    setCurrentIndex((prev) => (prev + 1) % profiles.length);
  }, [currentProfile, profiles.length]);

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#FF6B9D" />
          <Text style={styles.loadingText}>Finding people near you...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle-outline" size={64} color="#FF6B6B" />
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={loadProfiles}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  if (!currentProfile || profiles.length === 0) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.emptyContainer}>
          <Ionicons name="heart-outline" size={80} color="#CCC" />
          <Text style={styles.emptyTitle}>No more profiles</Text>
          <Text style={styles.emptySubtitle}>Check back later for new people!</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.logo}>Nudge</Text>
      </View>

      <ProfileCard profile={currentProfile} />

      <View style={styles.actions}>
        <TouchableOpacity style={styles.passButton} onPress={handlePass}>
          <Ionicons name="close" size={32} color="#FF6B6B" />
        </TouchableOpacity>
        <TouchableOpacity style={styles.likeButton} onPress={handleLike}>
          <Ionicons name="heart" size={32} color="#FFF" />
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

export default memo(HomeScreen);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    padding: 16,
    alignItems: 'center',
  },
  logo: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FF6B9D',
  },
  card: {
    flex: 1,
    margin: 16,
    borderRadius: 20,
    backgroundColor: '#FFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
    overflow: 'hidden',
  },
  image: {
    width: '100%',
    height: height * 0.5,
  },
  infoContainer: {
    padding: 20,
  },
  name: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  distance: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  bio: {
    fontSize: 16,
    color: '#666',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 20,
    paddingBottom: 32,
  },
  passButton: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#FFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  likeButton: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#FF6B9D',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#FF6B9D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 3,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  errorText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  retryButton: {
    marginTop: 24,
    backgroundColor: '#FF6B9D',
    paddingHorizontal: 32,
    paddingVertical: 12,
    borderRadius: 24,
  },
  retryText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
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
  },
  emptySubtitle: {
    fontSize: 16,
    color: '#666',
    marginTop: 8,
    textAlign: 'center',
  },
});
