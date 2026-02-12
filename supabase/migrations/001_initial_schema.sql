-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create spots table
CREATE TABLE IF NOT EXISTS public.spots (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    category TEXT,
    tags TEXT[],
    images TEXT[],
    created_by UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_count INTEGER DEFAULT 0,
    respect_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0
);

-- Create spot_lists table
CREATE TABLE IF NOT EXISTS public.spot_lists (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_count INTEGER DEFAULT 0,
    respect_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0
);

-- Create spot_list_items junction table
CREATE TABLE IF NOT EXISTS public.spot_list_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    spot_id UUID REFERENCES public.spots(id) ON DELETE CASCADE,
    list_id UUID REFERENCES public.spot_lists(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(spot_id, list_id)
);

-- Create user_respects table for tracking user interactions
CREATE TABLE IF NOT EXISTS public.user_respects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    spot_id UUID REFERENCES public.spots(id) ON DELETE CASCADE,
    list_id UUID REFERENCES public.spot_lists(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_follows table
CREATE TABLE IF NOT EXISTS public.user_follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_spots_location ON public.spots USING GIST (ST_Point(latitude, longitude));
CREATE INDEX IF NOT EXISTS idx_spots_created_by ON public.spots(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_lists_created_by ON public.spot_lists(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_spot_id ON public.spot_list_items(spot_id);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_list_id ON public.spot_list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_user_id ON public.user_respects(user_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_spot_id ON public.user_respects(spot_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_list_id ON public.user_respects(list_id);

-- Enforce uniqueness using an expression-based unique index (Postgres does not allow expressions in table-level UNIQUE constraints)
CREATE UNIQUE INDEX IF NOT EXISTS ux_user_respects_user_spot_list
ON public.user_respects (
  user_id,
  COALESCE(spot_id, '00000000-0000-0000-0000-000000000000'::UUID),
  COALESCE(list_id, '00000000-0000-0000-0000-000000000000'::UUID)
);

-- Create RLS (Row Level Security) policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spot_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spot_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_respects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

-- Users can read all public users
CREATE POLICY "Users can read all users" ON public.users
    FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Spots can be read by everyone
CREATE POLICY "Anyone can read spots" ON public.spots
    FOR SELECT USING (true);

-- Users can create spots
CREATE POLICY "Users can create spots" ON public.spots
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own spots
CREATE POLICY "Users can update own spots" ON public.spots
    FOR UPDATE USING (auth.uid() = created_by);

-- Users can delete their own spots
CREATE POLICY "Users can delete own spots" ON public.spots
    FOR DELETE USING (auth.uid() = created_by);

-- Spot lists can be read by everyone (if public)
CREATE POLICY "Anyone can read public lists" ON public.spot_lists
    FOR SELECT USING (is_public = true OR auth.uid() = created_by);

-- Users can create lists
CREATE POLICY "Users can create lists" ON public.spot_lists
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own lists
CREATE POLICY "Users can update own lists" ON public.spot_lists
    FOR UPDATE USING (auth.uid() = created_by);

-- Users can delete their own lists
CREATE POLICY "Users can delete own lists" ON public.spot_lists
    FOR DELETE USING (auth.uid() = created_by);

-- Spot list items can be read by everyone
CREATE POLICY "Anyone can read list items" ON public.spot_list_items
    FOR SELECT USING (true);

-- Users can manage items in their own lists
CREATE POLICY "Users can manage own list items" ON public.spot_list_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.spot_lists 
            WHERE id = spot_list_items.list_id 
            AND created_by = auth.uid()
        )
    );

-- User respects can be read by everyone
CREATE POLICY "Anyone can read respects" ON public.user_respects
    FOR SELECT USING (true);

-- Users can manage their own respects
CREATE POLICY "Users can manage own respects" ON public.user_respects
    FOR ALL USING (auth.uid() = user_id);

-- User follows can be read by everyone
CREATE POLICY "Anyone can read follows" ON public.user_follows
    FOR SELECT USING (true);

-- Users can manage their own follows
CREATE POLICY "Users can manage own follows" ON public.user_follows
    FOR ALL USING (auth.uid() = follower_id);

-- Create functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spots_updated_at BEFORE UPDATE ON public.spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spot_lists_updated_at BEFORE UPDATE ON public.spot_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
