-- ZUNO starter schema (review and deploy in Supabase SQL editor)
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique not null, display_name text not null default '',
 bio text default '', avatar_url text, created_at timestamptz default now()
);
create table if not exists public.videos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 caption text default '', video_url text not null, thumbnail_url text,
 visibility text not null default 'public' check (visibility in ('public','followers','private')),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz default now()
);
create table if not exists public.follows (
 follower_id uuid references public.profiles(id) on delete cascade,
 followed_id uuid references public.profiles(id) on delete cascade,
 created_at timestamptz default now(), primary key(follower_id,followed_id),
 check (follower_id <> followed_id)
);
create table if not exists public.likes (
 user_id uuid references public.profiles(id) on delete cascade,
 video_id uuid references public.videos(id) on delete cascade,
 created_at timestamptz default now(), primary key(user_id,video_id)
);
create table if not exists public.comments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete cascade,
 video_id uuid references public.videos(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 2000),
 created_at timestamptz default now()
);
create table if not exists public.reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid references public.profiles(id) on delete cascade,
 video_id uuid references public.videos(id) on delete cascade,
 reason text not null, details text, created_at timestamptz default now()
);
alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.reports enable row level security;
-- Add carefully scoped RLS policies before production launch. Do not expose reports/admin data.
