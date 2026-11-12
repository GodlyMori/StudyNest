-- ==============================================================================
-- Migration: V2 Stage 2 - topic_mastery table and RLS policies
-- ==============================================================================

create table if not exists public.topic_mastery (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    subject text not null,
    topic text not null,
    mastery double precision not null check (mastery >= 0.0 and mastery <= 1.0),
    updated_at timestamptz not null default now(),
    unique (user_id, subject, topic)
);

create index if not exists idx_topic_mastery_user_mastery
    on public.topic_mastery (user_id, mastery asc);

alter table public.topic_mastery enable row level security;

drop policy if exists "Users can insert own topic mastery" on public.topic_mastery;
create policy "Users can insert own topic mastery"
    on public.topic_mastery
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can view own topic mastery" on public.topic_mastery;
create policy "Users can view own topic mastery"
    on public.topic_mastery
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can update own topic mastery" on public.topic_mastery;
create policy "Users can update own topic mastery"
    on public.topic_mastery
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
