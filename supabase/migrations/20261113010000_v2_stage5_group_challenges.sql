-- Migration: Group Challenges, Challenge Attempts, and Leaderboard Read Access
-- Created: 2026-11-13
-- Description: Supports group quiz challenges, attempts tracking, and authenticated read access for group leaderboards.

-- 1. Leaderboard Read Access: allow authenticated users to view quiz scores across group members
drop policy if exists "Authenticated users can view quiz scores for leaderboards" on public.quiz_scores;
create policy "Authenticated users can view quiz scores for leaderboards"
    on public.quiz_scores
    for select
    to authenticated
    using (true);

-- 2. Group Challenges Table
create table if not exists public.group_challenges (
    id text primary key,
    group_id text not null,
    creator_id text not null,
    creator_name text not null,
    subject text not null,
    question_count int not null,
    created_at timestamptz not null default now()
);

alter table public.group_challenges enable row level security;

drop policy if exists "Authenticated users can view group challenges" on public.group_challenges;
create policy "Authenticated users can view group challenges"
    on public.group_challenges
    for select
    to authenticated
    using (true);

drop policy if exists "Authenticated users can create group challenges" on public.group_challenges;
create policy "Authenticated users can create group challenges"
    on public.group_challenges
    for insert
    to authenticated
    with check (auth.uid()::text = creator_id);

drop policy if exists "Creators can delete their own group challenges" on public.group_challenges;
create policy "Creators can delete their own group challenges"
    on public.group_challenges
    for delete
    to authenticated
    using (auth.uid()::text = creator_id);

-- 3. Challenge Attempts Table
create table if not exists public.challenge_attempts (
    id text primary key,
    challenge_id text not null references public.group_challenges(id) on delete cascade,
    user_id text not null,
    user_name text not null,
    score int not null,
    total int not null,
    percentage int not null,
    completed_at timestamptz not null default now()
);

alter table public.challenge_attempts enable row level security;

drop policy if exists "Authenticated users can view challenge attempts" on public.challenge_attempts;
create policy "Authenticated users can view challenge attempts"
    on public.challenge_attempts
    for select
    to authenticated
    using (true);

drop policy if exists "Users can insert own challenge attempts" on public.challenge_attempts;
create policy "Users can insert own challenge attempts"
    on public.challenge_attempts
    for insert
    to authenticated
    with check (auth.uid()::text = user_id);
