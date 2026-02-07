import { supabase } from '../config/supabase';
import { ChatMessage } from '../types';

export class ChatService {
  async sendMessage(matchId: string, senderId: string, text: string) {
    const { data, error } = await supabase
      .from('messages')
      .insert({
        match_id: matchId,
        sender_id: senderId,
        text,
        timestamp: new Date().toISOString(),
        ai_flagged: false,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getMessages(matchId: string): Promise<ChatMessage[]> {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('match_id', matchId)
      .order('timestamp', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  subscribeToMessages(matchId: string, callback: (message: ChatMessage) => void) {
    return supabase
      .channel(`messages:${matchId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          callback(payload.new as ChatMessage);
        }
      )
      .subscribe();
  }
}

export const chatService = new ChatService();
