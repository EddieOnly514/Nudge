-- Nudge App Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 18),
    gender TEXT NOT NULL,
    bio TEXT DEFAULT '',
    photos TEXT[] NOT NULL,
    approximate_location POINT,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences table
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    min_age INTEGER NOT NULL DEFAULT 18,
    max_age INTEGER NOT NULL DEFAULT 35,
    max_distance INTEGER NOT NULL DEFAULT 50,
    interested_in TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Prompts table
CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Likes table
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    liked_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, liked_user_id)
);

-- Passes table
CREATE TABLE passes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    liked_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, liked_user_id)
);

-- Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_1 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_2 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expired_at TIMESTAMP WITH TIME ZONE,
    match_type TEXT NOT NULL CHECK (match_type IN ('regular', 'nudge')),
    UNIQUE(user_1, user_2)
);

-- Chat messages table
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ai_flagged BOOLEAN DEFAULT FALSE
);

-- Nudges table (ephemeral)
CREATE TABLE nudges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location_context JSONB,
    is_revealed BOOLEAN DEFAULT FALSE
);

-- Nudge mode active users (ephemeral)
CREATE TABLE nudge_mode_active_users (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    location POINT NOT NULL,
    gender TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI Profiles table
CREATE TABLE ai_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    affinity_vector DOUBLE PRECISION[] DEFAULT ARRAY[]::DOUBLE PRECISION[],
    frequent_locations JSONB DEFAULT '[]'::JSONB,
    match_probability_map JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User interactions table (for AI learning)
CREATE TABLE user_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('viewed', 'liked', 'passed', 'matched', 'messaged', 'message_received')),
    pause_time DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Blocked users table
CREATE TABLE blocked_users (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, blocked_user_id)
);

-- Reports table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved'))
);

-- Indexes for performance
CREATE INDEX idx_users_location ON users USING GIST (approximate_location);
CREATE INDEX idx_users_age ON users(age);
CREATE INDEX idx_users_gender ON users(gender);
CREATE INDEX idx_users_last_active ON users(last_active);

CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_liked_user_id ON likes(liked_user_id);

CREATE INDEX idx_passes_user_id ON passes(user_id);
CREATE INDEX idx_passes_liked_user_id ON passes(liked_user_id);

CREATE INDEX idx_matches_user_1 ON matches(user_1);
CREATE INDEX idx_matches_user_2 ON matches(user_2);
CREATE INDEX idx_matches_created_at ON matches(created_at);

CREATE INDEX idx_chat_messages_match_id ON chat_messages(match_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp);

CREATE INDEX idx_nudges_receiver_id ON nudges(receiver_id);
CREATE INDEX idx_nudges_timestamp ON nudges(timestamp);

CREATE INDEX idx_nudge_active_location ON nudge_mode_active_users USING GIST (location);

CREATE INDEX idx_user_interactions_user_id ON user_interactions(user_id);
CREATE INDEX idx_user_interactions_timestamp ON user_interactions(timestamp);

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudges ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudge_mode_active_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (customize based on your auth setup)

-- Users can read all users (for matching)
CREATE POLICY "Users can view other users"
    ON users FOR SELECT
    USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Users can view matches they're part of
CREATE POLICY "Users can view their matches"
    ON matches FOR SELECT
    USING (auth.uid() = user_1 OR auth.uid() = user_2);

-- Users can view messages in their matches
CREATE POLICY "Users can view their messages"
    ON chat_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = chat_messages.match_id
            AND (matches.user_1 = auth.uid() OR matches.user_2 = auth.uid())
        )
    );

-- Users can insert messages in their matches
CREATE POLICY "Users can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = chat_messages.match_id
            AND (matches.user_1 = auth.uid() OR matches.user_2 = auth.uid())
        )
    );

-- Functions for cleanup

-- Cleanup old nudge mode sessions (older than 1 hour)
CREATE OR REPLACE FUNCTION cleanup_nudge_mode_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM nudge_mode_active_users
    WHERE timestamp < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- Cleanup old unrevealed nudges (older than 24 hours)
CREATE OR REPLACE FUNCTION cleanup_old_nudges()
RETURNS void AS $$
BEGIN
    DELETE FROM nudges
    WHERE is_revealed = FALSE
    AND timestamp < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Create a cron job to run cleanup functions (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-nudge-sessions', '*/30 * * * *', 'SELECT cleanup_nudge_mode_sessions()');
-- SELECT cron.schedule('cleanup-old-nudges', '0 * * * *', 'SELECT cleanup_old_nudges()');

-- Realtime configuration
-- Enable realtime for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_profiles_updated_at BEFORE UPDATE ON ai_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
