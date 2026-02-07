export interface User {
  id: string;
  name: string;
  age: number;
  gender: string;
  bio: string;
  photos: string[];
  preferences: UserPreferences;
  approximate_location?: Coordinate;
  last_active: string;
  prompts: Prompt[];
}

export interface UserPreferences {
  min_age: number;
  max_age: number;
  max_distance: number;
  interested_in: string[];
}

export interface Prompt {
  id: string;
  question: string;
  answer: string;
}

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export interface Match {
  id: string;
  user_1: string;
  user_2: string;
  created_at: string;
  expired_at?: string;
  match_type: 'regular' | 'nudge';
}

export interface Like {
  id: string;
  user_id: string;
  liked_user_id: string;
  timestamp: string;
}

export interface Nudge {
  id: string;
  sender_id: string;
  receiver_id: string;
  timestamp: string;
  location_context?: LocationContext;
  is_revealed: boolean;
}

export interface LocationContext {
  venue_name?: string;
  distance: number;
  coordinate: Coordinate;
}

export interface AnonymousNudge {
  id: string;
  distance: number;
  gender: string;
  has_nudged_you: boolean;
}

export interface ChatMessage {
  id: string;
  match_id: string;
  sender_id: string;
  content: string;
  timestamp: string;
  read: boolean;
}

export interface AIProfile {
  personality_traits: string[];
  interests: string[];
  communication_style: string;
  generated_bio?: string;
}
