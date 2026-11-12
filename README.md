# StudyNest

StudyNest is a Flutter study companion app for students. It combines subject quizzes, performance-based study recommendations, downloadable study materials, study session scheduling with local reminders, an Owl study assistant, and collaborative study groups with real-time chat.

## Features

- **Authentication & Guest Mode**: Sign up/sign in via Supabase Auth, or continue as a guest with automatic local score and attempt migration on registration.
- **Quizzes & Attempt Logging**: Subject quizzes (Calculus, Physics, Chemistry, Biology) with difficulty levels (`1`–`3`), per-question timing, Owl hints, and offline-first attempt logging (`AttemptLogger`).
- **Recommendations & Materials**: Topic-level weak-spot recommendations and offline-capable study materials / cheat sheets.
- **Study Planner & Notifications**: Schedule study sessions with date/time pickers and local notification reminders.
- **Study Groups & Realtime Chat**: Discover/create groups, invite peers, and chat in real time via Supabase Realtime.

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/GodlyMori/StudyNest.git
   cd StudyNest
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   - **Offline / unconfigured mode** (no Supabase credentials required):
     ```bash
     flutter run
     ```
   - **Connected mode** (with Supabase credentials):
     ```bash
     flutter run \
       --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
       --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
     ```

## Supabase Configuration

`SupabaseService.initialize()` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` at compile/run time via `String.fromEnvironment` (`--dart-define`). If either value is omitted, the app logs that credentials were not supplied and runs in offline/unconfigured mode.

> **Security rule**: Never commit `.env` files, API keys, service role keys, or anon keys to the repository. Always pass credentials via `--dart-define`.

## Database Migrations

SQL migrations live under `supabase/migrations/`:

- `20261109000000_phase1_and_phase5_setup.sql` — `profiles`, `quiz_scores`, `groups`, `group_members`, `group_invites`, `group_messages`, auth trigger, RLS policies, and Realtime publication.
- `20261112000000_v2_stage1_question_attempts.sql` — `question_attempts` table, indexes, and RLS policies.

**Workflow**:
- Always add a **new** timestamped migration file under `supabase/migrations/` for schema changes — **never edit an existing migration file** once applied.
- Apply migrations to your live Supabase project by running the SQL file in the **Supabase SQL Editor**.

## Running Tests & Static Analysis

Run the static analyzer:
```bash
flutter analyze
```

Run the test suite (37 tests):
```bash
flutter test
```

Tests run against local/in-memory fakes and `SharedPreferences` mocks; no live Supabase credentials are required.

## Folder Structure & Architecture

```text
lib/
├── main.dart            # App entry point, service initialization, theme
├── constants/           # App colors, asset paths, shared constants
├── theme/               # Material theme configuration
├── models/              # Immutable data models (e.g., QuizQuestion)
├── data/                # Static/seed content (quiz question bank, materials)
├── ml/                  # Pure Dart ML & telemetry layer (no Flutter widget deps)
│   ├── question_attempt.dart
│   └── attempt_logger.dart
├── services/            # App & backend services (SupabaseService, AttemptSyncService,
│                        # NotificationService, GuestScoreService, RecommendationEngine, etc.)
├── screens/             # Feature UI screens (auth, dashboard, quiz, materials,
│                        # planner, groups, owl_chat, profile, common)
└── widgets/             # Reusable UI widgets
```

### Layer Responsibilities

- **ML Layer (`lib/ml/`)**: Pure Dart models and logic (`QuestionAttempt`, `AttemptLogger`) with zero widget dependencies, making it directly unit-testable without `testWidgets`. Handles local attempt storage, guest-to-user migration, and offline outbox queuing.
- **Services (`lib/services/`)**: Integration and stateful business services wrapping Supabase (`SupabaseService`, `AttemptSyncService`), local persistence (`GuestScoreService`), notifications (`NotificationService`), and rule-based recommendations (`RecommendationEngine`).
- **Models (`lib/models/`)**: Core domain structures shared across data, services, and UI (e.g., `QuizQuestion` with difficulty levels `1`–`3`).
- **Screens (`lib/screens/`)**: Flutter UI screens organized by feature area (`auth`, `dashboard`, `quiz`, `materials`, `planner`, `groups`, `owl_chat`, `profile`, `common`).
