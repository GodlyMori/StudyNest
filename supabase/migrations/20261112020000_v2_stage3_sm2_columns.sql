-- ==============================================================================
-- Migration: V2 Stage 3 - SM-2 spaced-repetition columns on topic_mastery
-- Prerequisite: Must be run AFTER 20261112010000_v2_stage2_topic_mastery.sql
-- ==============================================================================

alter table public.topic_mastery
    add column if not exists next_review_at timestamptz,
    add column if not exists interval_days integer not null default 0 check (interval_days >= 0),
    add column if not exists ease double precision not null default 2.5 check (ease >= 1.3);

create index if not exists idx_topic_mastery_user_next_review
    on public.topic_mastery (user_id, next_review_at asc);
