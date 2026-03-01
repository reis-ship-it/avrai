-- Create storage buckets for different file types
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('user-avatars', 'user-avatars', true),
    ('spot-images', 'spot-images', true),
    ('list-images', 'list-images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for user avatars
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'user-avatars');

CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Set up storage policies for spot images
CREATE POLICY "Users can upload spot images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'spot-images');

CREATE POLICY "Anyone can view spot images" ON storage.objects
    FOR SELECT USING (bucket_id = 'spot-images');

CREATE POLICY "Users can update spot images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'spot-images');

CREATE POLICY "Users can delete spot images" ON storage.objects
    FOR DELETE USING (bucket_id = 'spot-images');

-- Set up storage policies for list images
CREATE POLICY "Users can upload list images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'list-images');

CREATE POLICY "Anyone can view list images" ON storage.objects
    FOR SELECT USING (bucket_id = 'list-images');

CREATE POLICY "Users can update list images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'list-images');

CREATE POLICY "Users can delete list images" ON storage.objects
    FOR DELETE USING (bucket_id = 'list-images');
