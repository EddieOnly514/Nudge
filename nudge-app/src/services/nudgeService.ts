import { supabase } from '../config/supabase';
import { Nudge, AnonymousNudge, Coordinate } from '../types';
import { locationService } from './locationService';

export class NudgeService {
  async sendNudge(receiverId: string, location: Coordinate) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('nudges')
      .insert({
        sender_id: user.id,
        receiver_id: receiverId,
        location_context: {
          coordinate: location,
          distance: 0, // Will be calculated
          venue_name: null,
        },
        is_revealed: false,
        timestamp: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getNearbyUsers(currentLocation: Coordinate, maxDistanceMeters: number = 100) {
    // Get all users who are recently active
    const { data: users, error } = await supabase
      .from('users')
      .select('id, gender, approximate_location')
      .gte('last_active', new Date(Date.now() - 30 * 60 * 1000).toISOString()); // Active in last 30 min

    if (error) throw error;
    if (!users) return [];

    // Filter by distance and map to anonymous representation
    const nearbyUsers: AnonymousNudge[] = [];

    for (const user of users) {
      if (!user.approximate_location) continue;

      // Parse location (format: "POINT(lng lat)" or [lat, lng])
      let userLocation: Coordinate;

      if (typeof user.approximate_location === 'string') {
        const match = user.approximate_location.match(/POINT\(([^\s]+)\s+([^\)]+)\)/);
        if (match) {
          userLocation = {
            longitude: parseFloat(match[1]),
            latitude: parseFloat(match[2]),
          };
        } else continue;
      } else if (Array.isArray(user.approximate_location)) {
        userLocation = {
          latitude: user.approximate_location[0],
          longitude: user.approximate_location[1],
        };
      } else continue;

      const distance = locationService.calculateDistance(currentLocation, userLocation);

      if (distance <= maxDistanceMeters) {
        // Check if they've nudged you
        const { data: nudges } = await supabase
          .from('nudges')
          .select('*')
          .eq('sender_id', user.id)
          .eq('receiver_id', (await supabase.auth.getUser()).data.user?.id || '');

        nearbyUsers.push({
          id: user.id,
          distance: Math.round(distance),
          gender: user.gender,
          has_nudged_you: (nudges?.length || 0) > 0,
        });
      }
    }

    return nearbyUsers.sort((a, b) => a.distance - b.distance);
  }

  async getReceivedNudges(): Promise<Nudge[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('nudges')
      .select('*')
      .eq('receiver_id', user.id)
      .order('timestamp', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getSentNudges(): Promise<Nudge[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('nudges')
      .select('*')
      .eq('sender_id', user.id)
      .order('timestamp', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async revealNudge(nudgeId: string) {
    const { data, error } = await supabase
      .from('nudges')
      .update({ is_revealed: true })
      .eq('id', nudgeId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  subscribeToNudges(callback: (nudge: Nudge) => void) {
    return supabase
      .channel('nudges')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'nudges',
        },
        (payload) => {
          callback(payload.new as Nudge);
        }
      )
      .subscribe();
  }
}

export const nudgeService = new NudgeService();
