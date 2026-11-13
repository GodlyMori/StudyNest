-- ==============================================================================
-- Migration: V2 Stage 5 - flashcards table and RLS policies
-- ==============================================================================

create table if not exists public.flashcards (
    id text primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    material_id text not null,
    front text not null,
    back text not null,
    ease double precision not null default 2.5,
    interval_days integer not null default 0,
    repetitions integer not null default 0,
    next_review_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_flashcards_user_next_review
    on public.flashcards (user_id, next_review_at asc);

alter table public.flashcards enable row level security;

drop policy if exists "Users can insert own flashcards" on public.flashcards;
create policy "Users can insert own flashcards"
    on public.flashcards
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can view own flashcards" on public.flashcards;
create policy "Users can view own flashcards"
    on public.flashcards
    for select
    to authenticated
    using (auth.uid() = user_id);

drop policy if exists "Users can update own flashcards" on public.flashcards;
create policy "Users can update own flashcards"
    on public.flashcards
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Users can delete own flashcards" on public.flashcards;
create policy "Users can delete own flashcards"
    on public.flashcards
    for delete
    to authenticated
    using (auth.uid() = user_id);
