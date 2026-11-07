# Supabase Storage notes for ZUNO

Consulted through the Supabase MCP `search_docs` tool on 2026-11-07.

- Supabase Flutter user-management guide: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
- Storage buckets fundamentals: https://supabase.com/docs/guides/storage/buckets/fundamentals
- Storage access control: https://supabase.com/docs/guides/storage/security/access-control

Relevant findings:
- Buckets are private by default. A public bucket lets anyone with the asset URL retrieve/serve that file; uploads, deletion, moves, and copies still require Storage RLS policies.
- Storage blocks uploads by default unless an `INSERT` policy permits the operation. An authenticated upload policy should be scoped by bucket ID and the user's folder/object path.
- Supabase Flutter supports Storage operations and public URLs for public assets. Client-side apps must use the publishable/anon key, never a service-role/secret key.

ZUNO implementation decision:
- Use a dedicated public bucket for public short-video media (the social feed requires playback without signed URL refresh).
- Permit authenticated users to upload only under a path prefixed by their Supabase user ID; keep update/delete restrictions owner-scoped.
- Limit uploaded media types and file size; continue to rely on RLS for the database row owner.
