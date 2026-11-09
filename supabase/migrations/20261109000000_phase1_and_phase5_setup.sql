-- ==============================================================================
-- Migration: Complete Database Schema for StudyNest (Phases 1 & 5)
-- Includes: profiles, quiz_scores, groups, group_members, group_invites, group_messages
-- Includes: auth triggers, Row-Level Security (RLS) policies, and Realtime publications
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Phase 1 Setup: Profiles Table & Auth Trigger
-- ------------------------------------------------------------------------------

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text not null default '',
    subjects text[] default '{}',
    level integer default 1,
    avatar_initials text,
    created_at timestamptz default now()
);

-- Trigger function to automatically create profile on registration
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    user_name text;
    initials text;
begin
    user_name := coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1));
    initials := upper(substring(user_name from 1 for 1));
    if initials is null or initials = '' then
        initials := 'S';
    end if;

    insert into public.profiles (id, display_name, subjects, level, avatar_initials, created_at)
    values (
        new.id,
        user_name,
        array['Calculus', 'Biology'],
        1,
        initials,
        now()
    )
    on conflict (id) do update
    set
        display_name = excluded.display_name,
        avatar_initials = excluded.avatar_initials;
    return new;
end;
$$;

-- Drop trigger if exists and recreate
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Enable RLS on profiles
alter table public.profiles enable row level security;

-- Profiles RLS Policies:
-- Authenticated users can view profiles (for user search, returning display_name, subjects, level, avatar_initials)
drop policy if exists "Authenticated users can search profiles" on public.profiles;
create policy "Authenticated users can search profiles"
    on public.profiles
    for select
    to authenticated
    using (true);

-- Users can update only their own profile
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
    on public.profiles
    for update
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- Users can insert their own profile (client fallback)
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
    on public.profiles
    for insert
    to authenticated
    with check (auth.uid() = id);


-- ------------------------------------------------------------------------------
-- 2. Phase 1 Setup: Quiz Scores Table & Policies
-- ------------------------------------------------------------------------------

create table if not exists public.quiz_scores (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    subject text not null,
    score int not null,
    grade text not null,
    created_at timestamptz default now()
);

alter table public.quiz_scores enable row level security;

drop policy if exists "Users can view own quiz scores" on public.quiz_scores;
create policy "Users can view own quiz scores"
    on public.quiz_scores
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can insert own quiz scores" on public.quiz_scores;
create policy "Users can insert own quiz scores"
    on public.quiz_scores
    for insert
    to authenticated
    with check (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 3. Phase 5 Setup: Study Groups Table
-- ------------------------------------------------------------------------------

create table if not exists public.groups (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    subject text not null,
    description text default '',
    created_by uuid references auth.users(id) on delete set null,
    is_public boolean default true,
    created_at timestamptz default now()
);

alter table public.groups enable row level security;

-- Groups RLS Policies:
-- Users can read public groups or groups they are members of
drop policy if exists "Users can view public or joined groups" on public.groups;
create policy "Users can view public or joined groups"
    on public.groups
    for select
    to authenticated
    using (
        is_public = true
        or exists (
            select 1 from public.group_members gm
            where gm.group_id = public.groups.id
            and gm.user_id = auth.uid()
        )
    );

-- Logged-in users can create study groups
drop policy if exists "Users can create study groups" on public.groups;
create policy "Users can create study groups"
    on public.groups
    for insert
    to authenticated
    with check (auth.uid() = created_by);


-- ------------------------------------------------------------------------------
-- 4. Phase 5 Setup: Group Members Table
-- ------------------------------------------------------------------------------

create table if not exists public.group_members (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text default 'member', -- 'admin', 'member'
    joined_at timestamptz default now(),
    unique(group_id, user_id)
);

alter table public.group_members enable row level security;

-- Group Members RLS Policies:
-- Members can view membership of groups they belong to or public groups
drop policy if exists "Users can view group members" on public.group_members;
create policy "Users can view group members"
    on public.group_members
    for select
    to authenticated
    using (
        user_id = auth.uid()
        or exists (
            select 1 from public.groups g
            where g.id = public.group_members.group_id
            and (g.is_public = true or exists (
                select 1 from public.group_members my_gm
                where my_gm.group_id = g.id and my_gm.user_id = auth.uid()
            ))
        )
    );

-- Users can join public groups or insert themselves
drop policy if exists "Users can join groups" on public.group_members;
create policy "Users can join groups"
    on public.group_members
    for insert
    to authenticated
    with check (auth.uid() = user_id);

-- Members can leave a group
drop policy if exists "Members can leave groups" on public.group_members;
create policy "Members can leave groups"
    on public.group_members
    for delete
    to authenticated
    using (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 5. Phase 5 Setup: Group Invites Table
-- ------------------------------------------------------------------------------

create table if not exists public.group_invites (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    inviter_id uuid references auth.users(id) on delete set null,
    invitee_id uuid not null references auth.users(id) on delete cascade,
    status text not null default 'pending', -- 'pending', 'accepted', 'declined'
    created_at timestamptz default now()
);

alter table public.group_invites enable row level security;

-- Group Invites RLS Policies:
-- Invitee and inviter can view their invites
drop policy if exists "Users can view their invites" on public.group_invites;
create policy "Users can view their invites"
    on public.group_invites
    for select
    to authenticated
    using (auth.uid() = invitee_id or auth.uid() = inviter_id);

-- Group members can send invites
drop policy if exists "Members can send invites" on public.group_invites;
create policy "Members can send invites"
    on public.group_invites
    for insert
    to authenticated
    with check (auth.uid() = inviter_id);

-- Invitee can update invite status (accept or decline)
drop policy if exists "Invitee can respond to invite" on public.group_invites;
create policy "Invitee can respond to invite"
    on public.group_invites
    for update
    to authenticated
    using (auth.uid() = invitee_id)
    with check (auth.uid() = invitee_id);


-- ------------------------------------------------------------------------------
-- 6. Phase 5 Setup: Group Messages Table (Realtime)
-- ------------------------------------------------------------------------------

create table if not exists public.group_messages (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    sender_id uuid references auth.users(id) on delete set null,
    content text not null,
    created_at timestamptz default now()
);

alter table public.group_messages enable row level security;

-- Group Messages RLS Policies:
-- Only group members can read group messages
drop policy if exists "Group members can view messages" on public.group_messages;
create policy "Group members can view messages"
    on public.group_messages
    for select
    to authenticated
    using (
        exists (
            select 1 from public.group_members gm
            where gm.group_id = public.group_messages.group_id
            and gm.user_id = auth.uid()
        )
    );

-- Only group members can send messages to that group
drop policy if exists "Group members can send messages" on public.group_messages;
create policy "Group members can send messages"
    on public.group_messages
    for insert
    to authenticated
    with check (
        auth.uid() = sender_id
        and exists (
            select 1 from public.group_members gm
            where gm.group_id = public.group_messages.group_id
            and gm.user_id = auth.uid()
        )
    );

-- Users can delete their own sent messages
drop policy if exists "Users can delete own messages" on public.group_messages;
create policy "Users can delete own messages"
    on public.group_messages
    for delete
    to authenticated
    using (auth.uid() = sender_id);


-- ------------------------------------------------------------------------------
-- 7. Supabase Realtime Setup
-- ------------------------------------------------------------------------------

-- Enable Realtime publication for messages and invites
do $$
begin
    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'group_messages'
    ) then
        alter publication supabase_realtime add table public.group_messages;
    end if;

    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'group_invites'
    ) then
        alter publication supabase_realtime add table public.group_invites;
    end if;
end;
$$;
