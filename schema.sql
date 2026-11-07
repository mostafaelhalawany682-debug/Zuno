-- ZUNO starter schema. Review before production and apply in the Supabase SQL editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique not null,
 display_name text not null default '',
 bio text default '',
 avatar_url text,
 created_at timestamptz default now()
);

create table if not exists public.videos (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 caption text default '',
 video_url text not null,
 thumbnail_url text,
 visibility text not null default 'public' check (visibility in ('public','followers','private')),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz default now()
);

create table if not exists public.follows (
 follower_id uuid references public.profiles(id) on delete cascade,
 followed_id uuid references public.profiles(id) on delete cascade,
 created_at timestamptz default now(),
 primary key(follower_id,followed_id),
 check (follower_id <> followed_id)
);

create table if not exists public.likes (
 user_id uuid references public.profiles(id) on delete cascade,
 video_id uuid references public.videos(id) on delete cascade,
 created_at timestamptz default now(),
 primary key(user_id,video_id)
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
 reason text not null,
 details text,
 created_at timestamptz default now()
);

-- Create one profile for each newly registered Supabase Auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_username text;
begin
  base_username := lower(regexp_replace(
    coalesce(new.raw_user_meta_data ->> 'username', 'zuno'),
    '[^a-zA-Z0-9_]', '', 'g'
  ));
  if length(base_username) < 3 then
    base_username := 'zuno';
  end if;

  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    left(base_username, 20) || '_' || right(replace(new.id::text, '-', ''), 8),
    coalesce(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Backfill profiles for Auth users that already existed before the trigger was installed.
insert into public.profiles (id, username, display_name)
select
  u.id,
  left(coalesce(nullif(lower(regexp_replace(coalesce(u.raw_user_meta_data ->> 'username', 'zuno'), '[^a-zA-Z0-9_]', '', 'g')), ''), 'zuno'), 20)
    || '_' || right(replace(u.id::text, '-', ''), 8),
  coalesce(u.raw_user_meta_data ->> 'display_name', '')
from auth.users as u
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.reports enable row level security;

-- Signed-in users may view profile cards; users may only edit their own profile.
drop policy if exists profiles_read_authenticated on public.profiles;
create policy profiles_read_authenticated
on public.profiles for select
to authenticated
using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- No client policies are added for videos, follows, likes, comments, or reports here.
-- Add separately reviewed, scoped policies before exposing those features.
