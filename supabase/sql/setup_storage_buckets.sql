-- Setup Storage Buckets for SPOTS
-- Run this in your Supabase SQL Editor after the main schema

-- Create storage buckets for different file types
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


