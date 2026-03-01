-- SPOTS Database Schema (Optimized)
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions in extensions schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "postgis" SCHEMA extensions;

-- Create api schema
CREATE SCHEMA IF NOT EXISTS api;

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS api.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create spots table with geometry column
CREATE TABLE IF NOT EXISTS api.spots (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location geometry(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    address TEXT,
    category TEXT,
    tags TEXT[],
    images TEXT[],
    created_by UUID REFERENCES api.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_count INTEGER DEFAULT 0,
    respect_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0
);

-- Create spot_lists table
CREATE TABLE IF NOT EXISTS api.spot_lists (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT true,
    created_by UUID REFERENCES api.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_count INTEGER DEFAULT 0,
    respect_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0
);

-- Create spot_list_items junction table
CREATE TABLE IF NOT EXISTS api.spot_list_items (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    spot_id UUID REFERENCES api.spots(id) ON DELETE CASCADE,
    list_id UUID REFERENCES api.spot_lists(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(spot_id, list_id)
);

-- Create user_respects table for tracking user interactions
CREATE TABLE IF NOT EXISTS api.user_respects (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES api.users(id) ON DELETE CASCADE,
    spot_id UUID REFERENCES api.spots(id) ON DELETE CASCADE,
    list_id UUID REFERENCES api.spot_lists(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_respect UNIQUE(user_id, spot_id, list_id)
);

-- Create user_follows table
CREATE TABLE IF NOT EXISTS api.user_follows (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES api.users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES api.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Enhanced Indexes
CREATE INDEX IF NOT EXISTS idx_spots_location ON api.spots USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_spots_tags ON api.spots USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_spots_created_by ON api.spots(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_lists_created_by ON api.spot_lists(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_spot_id ON api.spot_list_items(spot_id);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_list_id ON api.spot_list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_user_id ON api.user_respects(user_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_spot_id ON api.user_respects(spot_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_list_id ON api.user_respects(list_id);

-- Create RLS (Row Level Security) policies
ALTER TABLE api.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_respects ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_follows ENABLE ROW LEVEL SECURITY;

-- Users can read all public users
DROP POLICY IF EXISTS "Users can read all users" ON api.users;
CREATE POLICY "Users can read all users" ON api.users
    FOR SELECT USING (true);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON api.users;
CREATE POLICY "Users can update own profile" ON api.users
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON api.users;
CREATE POLICY "Users can insert own profile" ON api.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Spots can be read by everyone
DROP POLICY IF EXISTS "Anyone can read spots" ON api.spots;
CREATE POLICY "Anyone can read spots" ON api.spots
    FOR SELECT USING (true);

-- Users can create spots
DROP POLICY IF EXISTS "Users can create spots" ON api.spots;
CREATE POLICY "Users can create spots" ON api.spots
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own spots
DROP POLICY IF EXISTS "Users can update own spots" ON api.spots;
CREATE POLICY "Users can update own spots" ON api.spots
    FOR UPDATE USING (auth.uid() = created_by);

-- Users can delete their own spots
DROP POLICY IF EXISTS "Users can delete own spots" ON api.spots;
CREATE POLICY "Users can delete own spots" ON api.spots
    FOR DELETE USING (auth.uid() = created_by);

-- Spot lists can be read by everyone (if public)
DROP POLICY IF EXISTS "Anyone can read public lists" ON api.spot_lists;
CREATE POLICY "Anyone can read public lists" ON api.spot_lists
    FOR SELECT USING (is_public = true OR auth.uid() = created_by);

-- Users can create lists
DROP POLICY IF EXISTS "Users can create lists" ON api.spot_lists;
CREATE POLICY "Users can create lists" ON api.spot_lists
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own lists
DROP POLICY IF EXISTS "Users can update own lists" ON api.spot_lists;
CREATE POLICY "Users can update own lists" ON api.spot_lists
    FOR UPDATE USING (auth.uid() = created_by);

-- Users can delete their own lists
DROP POLICY IF EXISTS "Users can delete own lists" ON api.spot_lists;
CREATE POLICY "Users can delete own lists" ON api.spot_lists
    FOR DELETE USING (auth.uid() = created_by);

-- Spot list items can be read by everyone
DROP POLICY IF EXISTS "Anyone can read list items" ON api.spot_list_items;
CREATE POLICY "Anyone can read list items" ON api.spot_list_items
    FOR SELECT USING (true);

-- Simplified spot list items policy
DROP POLICY IF EXISTS "Users can manage own list items" ON api.spot_list_items;
CREATE POLICY "Users can manage own list items" ON api.spot_list_items
FOR ALL USING (
    list_id IN (SELECT id FROM api.spot_lists WHERE created_by = auth.uid())
);

-- User respects can be read by everyone
DROP POLICY IF EXISTS "Anyone can read respects" ON api.user_respects;
CREATE POLICY "Anyone can read respects" ON api.user_respects
    FOR SELECT USING (true);

-- Users can manage their own respects
DROP POLICY IF EXISTS "Users can manage own respects" ON api.user_respects;
CREATE POLICY "Users can manage own respects" ON api.user_respects
    FOR ALL USING (auth.uid() = user_id);

-- User follows can be read by everyone
DROP POLICY IF EXISTS "Anyone can read follows" ON api.user_follows;
CREATE POLICY "Anyone can read follows" ON api.user_follows
    FOR SELECT USING (true);

-- Users can manage their own follows
DROP POLICY IF EXISTS "Users can manage own follows" ON api.user_follows;
CREATE POLICY "Users can manage own follows" ON api.user_follows
    FOR ALL USING (auth.uid() = follower_id);

-- Updated function with explicit search path
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON api.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON api.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_spots_updated_at ON api.spots;
CREATE TRIGGER update_spots_updated_at BEFORE UPDATE ON api.spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_spot_lists_updated_at ON api.spot_lists;
CREATE TRIGGER update_spot_lists_updated_at BEFORE UPDATE ON api.spot_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO api.users (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('user-avatars', 'user-avatars', true),
    ('spot-images', 'spot-images', true),
    ('list-images', 'list-images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for user avatars
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'user-avatars');

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Set up storage policies for spot images
DROP POLICY IF EXISTS "Users can upload spot images" ON storage.objects;
CREATE POLICY "Users can upload spot images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'spot-images');

DROP POLICY IF EXISTS "Anyone can view spot images" ON storage.objects;
CREATE POLICY "Anyone can view spot images" ON storage.objects
    FOR SELECT USING (bucket_id = 'spot-images');

DROP POLICY IF EXISTS "Users can update spot images" ON storage.objects;
CREATE POLICY "Users can update spot images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'spot-images');

DROP POLICY IF EXISTS "Users can delete spot images" ON storage.objects;
CREATE POLICY "Users can delete spot images" ON storage.objects
    FOR DELETE USING (bucket_id = 'spot-images');

-- Set up storage policies for list images
DROP POLICY IF EXISTS "Users can upload list images" ON storage.objects;
CREATE POLICY "Users can upload list images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'list-images');

DROP POLICY IF EXISTS "Anyone can view list images" ON storage.objects;
CREATE POLICY "Anyone can view list images" ON storage.objects
    FOR SELECT USING (bucket_id = 'list-images');

DROP POLICY IF EXISTS "Users can update list images" ON storage.objects;
CREATE POLICY "Users can update list images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'list-images');

DROP POLICY IF EXISTS "Users can delete list images" ON storage.objects;
CREATE POLICY "Users can delete list images" ON storage.objects
    FOR DELETE USING (bucket_id = 'list-images');



