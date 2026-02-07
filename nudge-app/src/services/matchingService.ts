import { supabase } from '../config/supabase';
import { User, Match, Like } from '../types';

export class MatchingService {
  async getPotentialMatches(userId: string, preferences: any): Promise<User[]> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .neq('id', userId)
      .gte('age', preferences.min_age)
      .lte('age', preferences.max_age)
      .in('gender', preferences.interested_in);

    if (error) throw error;
    return data || [];
  }

  async likeUser(userId: string, likedUserId: string): Promise<Match | null> {
    // Create a like
    const { error: likeError } = await supabase.from('likes').insert({
      user_id: userId,
      liked_user_id: likedUserId,
      timestamp: new Date().toISOString(),
    });

    if (likeError) throw likeError;

    // Check if there's a mutual like
    const { data: mutualLike, error: checkError } = await supabase
      .from('likes')
      .select('*')
      .eq('user_id', likedUserId)
      .eq('liked_user_id', userId)
      .single();

    if (checkError && checkError.code !== 'PGRST116') throw checkError;

    // If mutual like exists, create a match
    if (mutualLike) {
      const { data: match, error: matchError } = await supabase
        .from('matches')
        .insert({
          user_1: userId,
          user_2: likedUserId,
          created_at: new Date().toISOString(),
          match_type: 'regular',
        })
        .select()
        .single();

      if (matchError) throw matchError;
      return match;
    }

    return null;
  }

  async getMatches(userId: string): Promise<Match[]> {
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .or(`user_1.eq.${userId},user_2.eq.${userId}`)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async passUser(userId: string, passedUserId: string) {
    // Just log the pass, no need to store
    console.log(`User ${userId} passed on ${passedUserId}`);
  }
}

export const matchingService = new MatchingService();
