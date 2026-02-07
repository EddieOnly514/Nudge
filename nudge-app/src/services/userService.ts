import { supabase } from '../config/supabase';
import { User, UserPreferences, Prompt } from '../types';

export class UserService {
  async createUser(userData: {
    name: string;
    age: number;
    gender: string;
    bio: string;
    photos: string[];
    preferences: UserPreferences;
    prompts: Prompt[];
  }) {
    const { data: { user: authUser } } = await supabase.auth.getUser();
    if (!authUser) throw new Error('Not authenticated');

    // Create user profile
    const { data: user, error: userError } = await supabase
      .from('users')
      .insert({
        id: authUser.id,
        name: userData.name,
        age: userData.age,
        gender: userData.gender,
        bio: userData.bio,
        photos: userData.photos,
      })
      .select()
      .single();

    if (userError) throw userError;

    // Create preferences
    const { error: prefsError } = await supabase
      .from('user_preferences')
      .insert({
        user_id: authUser.id,
        min_age: userData.preferences.min_age,
        max_age: userData.preferences.max_age,
        max_distance: userData.preferences.max_distance,
        interested_in: userData.preferences.interested_in,
      });

    if (prefsError) throw prefsError;

    // Create prompts
    if (userData.prompts.length > 0) {
      const { error: promptsError } = await supabase
        .from('prompts')
        .insert(
          userData.prompts.map((p) => ({
            user_id: authUser.id,
            question: p.question,
            answer: p.answer,
          }))
        );

      if (promptsError) throw promptsError;
    }

    return user;
  }

  async getUser(userId: string): Promise<User | null> {
    const { data, error } = await supabase
      .from('users')
      .select(`
        *,
        preferences:user_preferences(*),
        prompts(*)
      `)
      .eq('id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }

    return data;
  }

  async getCurrentUser(): Promise<User | null> {
    const { data: { user: authUser } } = await supabase.auth.getUser();
    if (!authUser) return null;

    return this.getUser(authUser.id);
  }

  async updateUser(userId: string, updates: Partial<User>) {
    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updatePreferences(userId: string, preferences: Partial<UserPreferences>) {
    const { data, error } = await supabase
      .from('user_preferences')
      .update(preferences)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateLocation(userId: string, latitude: number, longitude: number) {
    const { error } = await supabase
      .from('users')
      .update({
        approximate_location: `POINT(${longitude} ${latitude})`,
        last_active: new Date().toISOString(),
      })
      .eq('id', userId);

    if (error) throw error;
  }

  async searchUsers(filters: {
    minAge?: number;
    maxAge?: number;
    gender?: string[];
    excludeUserIds?: string[];
  }) {
    let query = supabase
      .from('users')
      .select('*')
      .order('last_active', { ascending: false });

    if (filters.minAge) {
      query = query.gte('age', filters.minAge);
    }

    if (filters.maxAge) {
      query = query.lte('age', filters.maxAge);
    }

    if (filters.gender && filters.gender.length > 0) {
      query = query.in('gender', filters.gender);
    }

    if (filters.excludeUserIds && filters.excludeUserIds.length > 0) {
      query = query.not('id', 'in', `(${filters.excludeUserIds.join(',')})`);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  }
}

export const userService = new UserService();
