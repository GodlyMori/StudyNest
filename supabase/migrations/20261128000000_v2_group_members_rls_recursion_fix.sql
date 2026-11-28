-- Migration: Fix group_members RLS infinite recursion
-- Created: 2026-11-28
-- Description: Adds security definer helper functions to check group membership without triggering
-- recursive RLS policy evaluations on public.group_members (resolves Postgres error 42P17).

-- 1. Helper function: is_group_member (uuid)
create or replace function public.is_group_member(p_group_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.group_members
    where group_id = p_group_id
      and user_id = auth.uid()
  );
$$;

-- 2. Helper function: is_group_member (text overload for tables using text group_id)
create or replace function public.is_group_member(p_group_id text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.group_members
    where group_id::text = p_group_id
      and user_id = auth.uid()
  );
$$;

-- 3. Helper function: shares_group_with (uuid) for leaderboard quiz scores
create or replace function public.shares_group_with(p_other_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.group_members gm_reader
    join public.group_members gm_owner
      on gm_reader.group_id = gm_owner.group_id
    where gm_reader.user_id = auth.uid()
      and gm_owner.user_id = p_other_user_id
  );
$$;

-- 4. Helper function: shares_group_with (text overload)
create or replace function public.shares_group_with(p_other_user_id text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.group_members gm_reader
    join public.group_members gm_owner
      on gm_reader.group_id = gm_owner.group_id
    where gm_reader.user_id = auth.uid()
      and gm_owner.user_id::text = p_other_user_id
  );
$$;

-- Grant execution permissions on helper functions
grant execute on function public.is_group_member(uuid) to authenticated, anon;
grant execute on function public.is_group_member(text) to authenticated, anon;
grant execute on function public.shares_group_with(uuid) to authenticated, anon;
grant execute on function public.shares_group_with(text) to authenticated, anon;

-- 5. Rewrite public.group_members SELECT policy (eliminates recursive self-reference)
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
            and (g.is_public = true or public.is_group_member(g.id))
        )
    );

-- 6. Rewrite public.groups SELECT policy
drop policy if exists "Users can view public or joined groups" on public.groups;
create policy "Users can view public or joined groups"
    on public.groups
    for select
    to authenticated
    using (
        is_public = true
        or public.is_group_member(public.groups.id)
    );

-- 7. Rewrite public.group_messages SELECT and INSERT policies
drop policy if exists "Group members can read messages" on public.group_messages;
create policy "Group members can read messages"
    on public.group_messages
    for select
    to authenticated
    using (
        public.is_group_member(public.group_messages.group_id)
    );

drop policy if exists "Group members can send messages" on public.group_messages;
create policy "Group members can send messages"
    on public.group_messages
    for insert
    to authenticated
    with check (
        public.is_group_member(public.group_messages.group_id)
        and user_id = auth.uid()
    );

-- 8. Rewrite public.quiz_scores leaderboard policy
drop policy if exists "Authenticated users can view quiz scores for leaderboards" on public.quiz_scores;
create policy "Authenticated users can view quiz scores for leaderboards"
    on public.quiz_scores
    for select
    to authenticated
    using (
        public.shares_group_with(public.quiz_scores.user_id)
    );

-- 9. Rewrite public.group_challenges SELECT policy
drop policy if exists "Authenticated users can view group challenges" on public.group_challenges;
create policy "Authenticated users can view group challenges"
    on public.group_challenges
    for select
    to authenticated
    using (
        public.is_group_member(public.group_challenges.group_id)
    );

-- 10. Rewrite public.challenge_attempts SELECT policy
drop policy if exists "Authenticated users can view challenge attempts" on public.challenge_attempts;
create policy "Authenticated users can view challenge attempts"
    on public.challenge_attempts
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.group_challenges gc
            where gc.id = public.challenge_attempts.challenge_id
              and public.is_group_member(gc.group_id)
        )
    );
