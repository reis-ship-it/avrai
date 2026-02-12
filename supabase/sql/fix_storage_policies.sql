-- Fix storage policies for anonymous access
-- Run this in your Supabase SQL Editor

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Grant access to anon role for storage
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.buckets TO anon;

-- Create permissive policies for testing
DROP POLICY IF EXISTS "Allow all storage access" ON storage.objects;
CREATE POLICY "Allow all storage access" ON storage.objects
    FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all bucket access" ON storage.buckets;
CREATE POLICY "Allow all bucket access" ON storage.buckets
    FOR ALL USING (true);

-- Also try to grant storage usage
GRANT USAGE ON SCHEMA storage TO anon;


