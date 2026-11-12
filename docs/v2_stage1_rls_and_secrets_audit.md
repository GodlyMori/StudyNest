# V2 Stage 1 — RLS Audit & Secrets Check (Task 1.5)

## 1. Row-Level Security (RLS) Audit

Audited from the SQL migration files in `supabase/migrations/`:
- `supabase/migrations/20261109000000_phase1_and_phase5_setup.sql`
- `supabase/migrations/20261112000000_v2_stage1_question_attempts.sql`

> **Note on live status**: Migration files in the repository are verified below. Whether the live Supabase project has these exact policies applied without manual drift **needs human verification** in the Supabase Dashboard (Database → Tables / Policies), except `question_attempts` which was confirmed live prior to this audit.

| Table | RLS Enabled (Migration) | Policies Defined in Migrations | Live DB Status |
| :--- | :--- | :--- | :--- |
| `public.profiles` | **ON** (`enable row level security`) | 1. `"Authenticated users can search profiles"` (`SELECT`, `authenticated`, `using (true)`)<br>2. `"Users can update own profile"` (`UPDATE`, `authenticated`, `using (auth.uid() = id) with check (auth.uid() = id)`)<br>3. `"Users can insert own profile"` (`INSERT`, `authenticated`, `with check (auth.uid() = id)`) | Needs human verification |
| `public.quiz_scores` | **ON** (`enable row level security`) | 1. `"Users can view own quiz scores"` (`SELECT`, `authenticated`, `using (auth.uid() = user_id)`)<br>2. `"Users can insert own quiz scores"` (`INSERT`, `authenticated`, `with check (auth.uid() = user_id)`) | Needs human verification |
| `public.groups` | **ON** (`enable row level security`) | 1. `"Users can view public or joined groups"` (`SELECT`, `authenticated`, `is_public = true` or member in `group_members`)<br>2. `"Users can create study groups"` (`INSERT`, `authenticated`, `with check (auth.uid() = created_by)`) | Needs human verification |
| `public.group_members` | **ON** (`enable row level security`) | 1. `"Users can view group members"` (`SELECT`, `authenticated`, own row or public/joined group)<br>2. `"Users can join groups"` (`INSERT`, `authenticated`, `with check (auth.uid() = user_id)`)<br>3. `"Members can leave groups"` (`DELETE`, `authenticated`, `using (auth.uid() = user_id)`) | Needs human verification |
| `public.group_invites` | **ON** (`enable row level security`) | 1. `"Users can view their invites"` (`SELECT`, `authenticated`, `auth.uid() = invitee_id or auth.uid() = inviter_id`)<br>2. `"Members can send invites"` (`INSERT`, `authenticated`, `with check (auth.uid() = inviter_id)`)<br>3. `"Invitee can respond to invite"` (`UPDATE`, `authenticated`, `using (auth.uid() = invitee_id) with check (auth.uid() = invitee_id)`) | Needs human verification |
| `public.group_messages` | **ON** (`enable row level security`) | 1. `"Group members can view messages"` (`SELECT`, `authenticated`, member of `group_id`)<br>2. `"Group members can send messages"` (`INSERT`, `authenticated`, `auth.uid() = sender_id` and member of `group_id`)<br>3. `"Users can delete own messages"` (`DELETE`, `authenticated`, `using (auth.uid() = sender_id)`) | Needs human verification |
| `public.question_attempts` | **ON** (`enable row level security`) | 1. `"Users can insert own question attempts"` (`INSERT`, `authenticated`, `with check (auth.uid() = user_id)`)<br>2. `"Users can view own question attempts"` (`SELECT`, `authenticated`, `using (auth.uid() = user_id)`) | Confirmed live (per Stage 1 handoff); verify in dashboard if needed |

### Policy Observations
- All 7 tables have `enable row level security` enabled and restrict access to the `authenticated` role.
- `profiles` intentionally allows `SELECT` (`using (true)`) for `authenticated` users to support in-app user search (`Find Users`).
- All user-owned tables (`quiz_scores`, `question_attempts`) scope reads and writes to `auth.uid() = user_id`.
- `group_messages` restricts both `SELECT` and `INSERT` to verified members of the target `group_id`, and restricts `DELETE` to `auth.uid() = sender_id`.

## 2. Secrets & Keys Scan

### Checks Executed
1. Tracked filenames checked for `.env`, `secret`, `key`, `credential`:
   - `git ls-files | Select-String -Pattern '\.env|secret|key|credential' -CaseSensitive:$false` → **0 matches**.
2. Tracked file contents scanned for JWTs, Supabase keys/URLs, Google/GitHub/AWS key patterns:
   - `git grep -n -E "eyJ[A-Za-z0-9_-]{10,}\.|sb_publishable_|sb_secret_|service_role|AIza[0-9A-Za-z_-]{20,}|ghp_[0-9A-Za-z]{20,}|AKIA[0-9A-Z]{16}|supabase\.co"` → **1 match**: placeholder example `https://<your-project-ref>.supabase.co` in `README.md:34`.
3. Full git history scanned:
   - `git log --all --stat -- "*.env*" "*secret*" "*credential*"` → **0 matches**.
   - `git log --all -S "eyJ" --oneline` → **0 matches**.
   - `git log --all -S "service_role" --oneline` → **0 matches**.
   - `git log --all -S "sb_publishable_" --oneline` and `sb_secret_` → **0 matches**.
   - `git log --all -S "supabase.co" --oneline` → **1 match**: `293920b` (`README.md` placeholder only).
4. Supabase initialization verified via `git grep -n "SUPABASE_"`:
   - `lib/services/supabase_service.dart:8-9` uses `String.fromEnvironment('SUPABASE_URL', defaultValue: '')` and `String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')` (`--dart-define`).

### Result
**No secrets, API keys, `.env` files, or live Supabase URLs are committed in the working tree or git history.**
