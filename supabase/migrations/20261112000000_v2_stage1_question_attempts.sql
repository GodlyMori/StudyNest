-- ==============================================================================
-- Migration: V2 Stage 1 - question_attempts table and RLS policies
-- ==============================================================================

create table if not exists public.question_attempts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    question_id text not null,
    subject text not null,
    topic text not null,
    correct boolean not null,
    time_taken_ms integer not null check (time_taken_ms >= 0),
    hint_used boolean not null default false,
    answered_at timestamptz not null default now()
);

create index if not exists idx_question_attempts_user_answered
    on public.question_attempts (user_id, answered_at desc);

create index if not exists idx_question_attempts_user_question
    on public.question_attempts (user_id, question_id);

alter table public.question_attempts enable row level security;

drop policy if exists "Users can insert own question attempts" on public.question_attempts;
create policy "Users can insert own question attempts"
    on public.question_attempts
    for insert
    to authenticated
    with check (auth.uid() = user_id);

drop policy if exists "Users can view own question attempts" on public.question_attempts;
create policy "Users can view own question attempts"
    on public.question_attempts
    for select
    to authenticated
    using (auth.uid() = user_id);
