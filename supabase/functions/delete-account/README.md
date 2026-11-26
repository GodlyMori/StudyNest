# Supabase Edge Function: `delete-account`

## Overview
This Edge Function securely deletes a user's authentication identity from `auth.users` using Supabase's `service_role` admin API (`adminClient.auth.admin.deleteUser(userId)`).

The client Flutter application cleans up all user-owned public table records first (preserving foreign key constraints and cascade order: `quiz_scores`, `group_members`, `group_messages`, `group_invites` as invitee, `group_invites` as inviter, and `profiles`), and then invokes this Edge Function with the caller's authenticated session JWT.

---

## Secret Configuration (CRITICAL SECURITY RULE)

> **WARNING**: The Supabase `service_role` key grants administrative access to bypass Row Level Security and modify `auth.users`.
> **The `service_role` key must NEVER ship in the Flutter app, NEVER be committed to the repository, NEVER appear in tests, and NEVER appear in chat.**

### Exact Secret Name
- Secret Name: `SUPABASE_SERVICE_ROLE_KEY` (fallback: `SERVICE_ROLE_KEY`)
- Standard environment variables provided automatically by Supabase runtime: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

### Where to Set the Secret
You can set this secret in one of two places:

1. **Via Supabase Dashboard**:
   - Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Select your StudyNest project.
   - Navigate to **Project Settings** (gear icon) -> **API**.
   - Copy the `service_role` key (keep it private).
   - Navigate to **Edge Functions** (left sidebar).
   - Under **Secrets** / **Function Secrets**, click **Add Secret**.
   - Name: `SUPABASE_SERVICE_ROLE_KEY`
   - Value: *(paste your service_role key here)*
   - Save.

2. **Via Supabase CLI**:
   ```bash
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>
   ```

---

## Deployment Status: Needs Human Verification

**Antigravity Environment Status**:
- Antigravity cannot deploy the function directly to your live Supabase project because the `supabase` CLI is not installed locally and Antigravity has no administrative access or access tokens to your Supabase cloud project.
- **Deployment Status**: `Needs human verification` (requires Alvin to execute the deployment command below or upload via dashboard).

---

## Deployment Instructions for Alvin

### Option A: Using the Supabase CLI (Recommended)

1. Open your terminal in the repository root directory (`study_nest` or workspace root where `supabase/` lives).
2. Login to your Supabase account if you haven't already:
   ```bash
   supabase login
   ```
3. Link your local project to your remote Supabase project:
   ```bash
   supabase link --project-ref <your-project-ref>
   ```
   *(Your project reference is found in your Supabase project URL: `https://supabase.com/dashboard/project/<your-project-ref>`)*
4. Set the `SUPABASE_SERVICE_ROLE_KEY` secret (if not already set in dashboard):
   ```bash
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
   ```
5. Deploy the `delete-account` edge function:
   ```bash
   supabase functions deploy delete-account --no-verify-jwt
   ```
   *(Note: The function self-verifies the user JWT in `Authorization` header to enforce that users may only delete their own identity.)*

### Option B: Via Supabase Dashboard
1. Go to **Edge Functions** in your Supabase Project Dashboard.
2. Click **Create Function**, name it `delete-account`.
3. Paste the contents of `supabase/functions/delete-account/index.ts`.
4. Deploy the function.

---

## Live Verification Checklist (Human Verification Required)

Do **NOT** claim the `auth.users` row is deleted until performing the following live check:

1. Create a disposable test user (e.g. `test-delete@example.com`) in the app or via Supabase Auth.
2. Verify the user appears in **Supabase Dashboard** -> **Authentication** -> **Users**.
3. Log in to the app with that user and navigate to **Settings** -> **Delete Account**.
4. Confirm deletion ("Permanently Delete Account").
5. Refresh **Supabase Dashboard** -> **Authentication** -> **Users**.
6. Verify that:
   - The user row is completely removed from `auth.users`.
   - The user row is removed from `public.profiles`.
   - Any messages, scores, or memberships for that user are removed.
   - The app signs out to `WelcomeScreen`.
