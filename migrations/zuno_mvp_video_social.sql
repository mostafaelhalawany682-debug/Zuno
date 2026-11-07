-- ZUNO MVP: public short-video bucket with owner-scoped writes.
-- Existing public feed reads are intentional; writes require an authenticated owner.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'zuno-videos',
  'zuno-videos',
  true,
  104857600,
  ARRAY['video/mp4', 'video/quicktime', 'video/webm']::text[]
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "ZUNO public video objects are readable"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'zuno-videos');

CREATE POLICY "ZUNO users upload to own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'zuno-videos'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

CREATE POLICY "ZUNO users delete own video objects"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'zuno-videos'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

CREATE POLICY "ZUNO users follow other accounts"
ON public.follows
FOR INSERT
TO authenticated
WITH CHECK (
  follower_id = (SELECT auth.uid())
  AND follower_id <> following_id
);

CREATE POLICY "ZUNO users unfollow own relationships"
ON public.follows
FOR DELETE
TO authenticated
USING (follower_id = (SELECT auth.uid()));
