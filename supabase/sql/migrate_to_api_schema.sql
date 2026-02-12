-- Migrate tables from public to api schema
-- Run this in your Supabase SQL Editor

-- Create api schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS api;

-- Move users table
CREATE TABLE IF NOT EXISTS api.users AS SELECT * FROM public.users;
DROP TABLE IF EXISTS public.users;

-- Move spots table  
CREATE TABLE IF NOT EXISTS api.spots AS SELECT * FROM public.spots;
DROP TABLE IF EXISTS public.spots;

-- Move spot_lists table
CREATE TABLE IF NOT EXISTS api.spot_lists AS SELECT * FROM public.spot_lists;
DROP TABLE IF EXISTS public.spot_lists;

-- Move spot_list_items table
CREATE TABLE IF NOT EXISTS api.spot_list_items AS SELECT * FROM public.spot_list_items;
DROP TABLE IF EXISTS public.spot_list_items;

-- Move user_respects table
CREATE TABLE IF NOT EXISTS api.user_respects AS SELECT * FROM public.user_respects;
DROP TABLE IF EXISTS public.user_respects;

-- Move user_follows table
CREATE TABLE IF NOT EXISTS api.user_follows AS SELECT * FROM public.user_follows;
DROP TABLE IF EXISTS public.user_follows;

-- Recreate indexes in api schema
CREATE INDEX IF NOT EXISTS idx_spots_location ON api.spots USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_spots_tags ON api.spots USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_spots_created_by ON api.spots(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_lists_created_by ON api.spot_lists(created_by);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_spot_id ON api.spot_list_items(spot_id);
CREATE INDEX IF NOT EXISTS idx_spot_list_items_list_id ON api.spot_list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_user_id ON api.user_respects(user_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_spot_id ON api.user_respects(spot_id);
CREATE INDEX IF NOT EXISTS idx_user_respects_list_id ON api.user_respects(list_id);

-- Enable RLS on api tables
ALTER TABLE api.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_respects ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_follows ENABLE ROW LEVEL SECURITY;

-- Recreate policies in api schema
DROP POLICY IF EXISTS "Users can read all users" ON api.users;
CREATE POLICY "Users can read all users" ON api.users
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON api.users;
CREATE POLICY "Users can update own profile" ON api.users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON api.users;
CREATE POLICY "Users can insert own profile" ON api.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Spots policies
DROP POLICY IF EXISTS "Anyone can read spots" ON api.spots;
CREATE POLICY "Anyone can read spots" ON api.spots
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create spots" ON api.spots;
CREATE POLICY "Users can create spots" ON api.spots
    FOR INSERT WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can update own spots" ON api.spots;
CREATE POLICY "Users can update own spots" ON api.spots
    FOR UPDATE USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can delete own spots" ON api.spots;
CREATE POLICY "Users can delete own spots" ON api.spots
    FOR DELETE USING (auth.uid() = created_by);

-- Spot lists policies
DROP POLICY IF EXISTS "Anyone can read public lists" ON api.spot_lists;
CREATE POLICY "Anyone can read public lists" ON api.spot_lists
    FOR SELECT USING (is_public = true OR auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can create lists" ON api.spot_lists;
CREATE POLICY "Users can create lists" ON api.spot_lists
    FOR INSERT WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can update own lists" ON api.spot_lists;
CREATE POLICY "Users can update own lists" ON api.spot_lists
    FOR UPDATE USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can delete own lists" ON api.spot_lists;
CREATE POLICY "Users can delete own lists" ON api.spot_lists
    FOR DELETE USING (auth.uid() = created_by);

-- Spot list items policies
DROP POLICY IF EXISTS "Anyone can read list items" ON api.spot_list_items;
CREATE POLICY "Anyone can read list items" ON api.spot_list_items
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own list items" ON api.spot_list_items;
CREATE POLICY "Users can manage own list items" ON api.spot_list_items
FOR ALL USING (
    list_id IN (SELECT id FROM api.spot_lists WHERE created_by = auth.uid())
);

-- User respects policies
DROP POLICY IF EXISTS "Anyone can read respects" ON api.user_respects;
CREATE POLICY "Anyone can read respects" ON api.user_respects
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own respects" ON api.user_respects;
CREATE POLICY "Users can manage own respects" ON api.user_respects
    FOR ALL USING (auth.uid() = user_id);

-- User follows policies
DROP POLICY IF EXISTS "Anyone can read follows" ON api.user_follows;
CREATE POLICY "Anyone can read follows" ON api.user_follows
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own follows" ON api.user_follows;
CREATE POLICY "Users can manage own follows" ON api.user_follows
    FOR ALL USING (auth.uid() = follower_id);

-- Recreate triggers in api schema
DROP TRIGGER IF EXISTS update_users_updated_at ON api.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON api.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_spots_updated_at ON api.spots;
CREATE TRIGGER update_spots_updated_at BEFORE UPDATE ON api.spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_spot_lists_updated_at ON api.spot_lists;
CREATE TRIGGER update_spot_lists_updated_at BEFORE UPDATE ON api.spot_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


