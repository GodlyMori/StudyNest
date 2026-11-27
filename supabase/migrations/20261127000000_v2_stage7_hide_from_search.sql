-- ==============================================================================
-- Migration: V2 Stage 7 - Add hidden_from_search flag to public.profiles
-- Allows users to opt out of appearing in Find Users search results.
--
-- Honest limitation:
-- The public.profiles SELECT RLS policy is broad (using (true) - any
-- authenticated user can read profile rows). This toggle hides the user from
-- Find Users SEARCH RESULTS only; it does not make the row unreadable by
-- direct ID lookup.
-- ==============================================================================

alter table public.profiles
    add column if not exists hidden_from_search boolean not null default false;
