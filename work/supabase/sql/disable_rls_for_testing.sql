-- Temporarily disable RLS for testing
-- Run this in your Supabase SQL Editor

-- Disable RLS on all tables
ALTER TABLE api.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE api.spots DISABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_lists DISABLE ROW LEVEL SECURITY;
ALTER TABLE api.spot_list_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_respects DISABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_follows DISABLE ROW LEVEL SECURITY;

-- Add a simple policy that allows all operations for testing
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.users FOR ALL USING (true);
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.spots FOR ALL USING (true);
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.spot_lists FOR ALL USING (true);
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.spot_list_items FOR ALL USING (true);
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.user_respects FOR ALL USING (true);
CREATE POLICY IF NOT EXISTS "Allow all for testing" ON api.user_follows FOR ALL USING (true);


