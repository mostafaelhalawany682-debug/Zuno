-- ZUNO bootstrap schema for a fresh Supabase project.
-- For the already-linked project, use the incremental migrations in /migrations instead.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  full_name text,
  display_name text not null default '',
  avatar_url text,
  bio text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  video_url text not null,
  caption text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists public.likes (
  video_id uuid not null references public.videos(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (video_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.videos(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  video_id uuid references public.videos(id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz not null default now()
);

create index if not exists videos_created_at_idx on public.videos (created_at desc);
create index if not exists videos_user_id_idx on public.videos (user_id, created_at desc);
create index if not exists comments_video_created_at_idx on public.comments (video_id, created_at desc);
create index if not exists follows_following_id_idx on public.follows (following_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_username text;
  display_name_value text;
begin
  base_username := lower(regexp_replace(
    coalesce(new.raw_user_meta_data ->> 'username', 'zuno'),
    '[^a-zA-Z0-9_]', '', 'g'
  ));
  if length(base_username) < 3 then
    base_username := 'zuno';
  end if;
  display_name_value := coalesce(
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name',
    ''
  );

  insert into public.profiles (id, username, full_name, display_name)
  values (
    new.id,
    left(base_username, 20) || '_' || right(replace(new.id::text, '-', ''), 8),
    display_name_value,
    display_name_value
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.reports enable row level security;

drop policy if exists profiles_public_select on public.profiles;
create policy profiles_public_select on public.profiles
for select to public using (true);
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
for insert to authenticated with check ((select auth.uid()) = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists videos_public_select on public.videos;
create policy videos_public_select on public.videos
for select to public using (true);
drop policy if exists videos_insert_own on public.videos;
create policy videos_insert_own on public.videos
for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists videos_update_own on public.videos;
create policy videos_update_own on public.videos
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
drop policy if exists videos_delete_own on public.videos;
create policy videos_delete_own on public.videos
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists comments_public_select on public.comments;
create policy comments_public_select on public.comments
for select to public using (true);
drop policy if exists comments_insert_own on public.comments;
create policy comments_insert_own on public.comments
for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists comments_delete_own on public.comments;
create policy comments_delete_own on public.comments
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists likes_public_select on public.likes;
create policy likes_public_select on public.likes
for select to public using (true);
drop policy if exists likes_insert_own on public.likes;
create policy likes_insert_own on public.likes
for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists likes_delete_own on public.likes;
create policy likes_delete_own on public.likes
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists follows_public_select on public.follows;
create policy follows_public_select on public.follows
for select to public using (true);
drop policy if exists follows_insert_own on public.follows;
create policy follows_insert_own on public.follows
for insert to authenticated with check (
  (select auth.uid()) = follower_id and follower_id <> following_id
);
drop policy if exists follows_delete_own on public.follows;
create policy follows_delete_own on public.follows
for delete to authenticated using ((select auth.uid()) = follower_id);

-- The video bucket and owner-scoped Storage policies are in
-- migrations/zuno_mvp_video_social.sql.
