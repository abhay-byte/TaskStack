# Finished Tasks

## ✅ Phase 0 — Initial Setup
- Docs: problem_statement, SRS, SDD, ui-ux, design-principles
- todo/ongoing/finished task tracking files
- Material Design 3 component docs copied to `docs/ui/`
- Flutter project initialized (Clean Architecture folder structure)
- GitHub repo created and initial commit pushed

---

## ✅ Phase 1 — Data & Infrastructure
- Drift tables: `TasksTable`, `TagsTable`, `DailySummariesTable`
- DAOs: `TaskDao`, `TagDao`, `AnalyticsDao`
- `AppDatabase`: WAL mode, foreign keys, Riverpod providers, build_runner codegen
- `Task` domain entity (enums, isInProgress, startTime, copyWith)
- `TaskRepository` interface + `TaskRepositoryImpl` (row↔entity mapping, JSON tags)
- Use cases: `CreateTask`, `GetTasksForDate`, `Update`, `Delete`, `Complete` (undo), `Duplicate`
- `NotificationScheduler`: timezone-aware zonedSchedule, per-task offset, deeplink
- `NotificationService`: plugin singleton, permission requests, `onNotificationTapped` hook

---

## ✅ Phase 2 — Providers & Settings
- `SettingsNotifier` + `AppSettings` (SharedPreferences-backed)
- 10× Riverpod task providers (date, stream, sorted, use cases, form state)
- `TaskFormState` + `TaskFormNotifier` (autoDispose, 13 fields, save logic)
- `AppRouter` (GoRouter: onboarding redirect, ShellRoute 3 tabs, modal routes, notification deep-link)
- `main.dart`: initialises notifications + SharedPreferences before runApp

---

## ✅ Phase 3 — UI Screens
- **TaskStackScreen**: 24-hour timeline, auto-scroll, 30s time indicator, date nav, empty state, FAB
- **TaskCardWidget**: swipe-to-done (Dismissible), long-press context menu, pending/active/done states, tag pills
- **TimeIndicatorWidget**: red circle + line at current minute
- **TaskFormScreen**: 13 fields — title + desc + purpose + accent + tags + time + duration + recurrence + interval + notification offset
- **TaskDetailScreen**: full view, edit/delete/done-undo actions
- **AnalyticsScreen**: 4 tabs — daily (bar+pie), weekly (score bars), monthly (heatmap calendar), yearly (365-dot grid)
- **SettingsScreen**: theme, accent, 24h, week start, reminder offset, JSON export/import, clear today, licences
- **OnboardingScreen**: 4-page PageView, SmoothPageIndicator, skip, permission request

---

## ✅ Phase 4 — Remaining Features (v1.0 Complete)
- **GitHub Actions CI/CD**: `.github/workflows/ci.yml` — analyze + test + build APK on every push/PR
- **AppConfig (flavours)**: `lib/core/config/app_config.dart` + `docs/flavour-config.md`
- **Unit tests**: `test/domain/task_entity_test.dart`, `test/domain/settings_entity_test.dart`
- **Widget tests**: `test/widgets/task_card_widget_test.dart`
- **Integration test scaffold**: `integration_test/app_test.dart` (onboarding + stack screen smoke tests)
- **Android BootReceiver**: `BootReceiver.kt` + registered in `AndroidManifest.xml`
- **Android permissions**: BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM, POST_NOTIFICATIONS
- **ProductivityScoreService**: calculates weighted score (70% completion + 30% duration), upserts DailySummary
- **NextOccurrenceScheduler**: auto-creates + schedules next daily/weekly task instance on completion
- **JsonImportService**: file_picker integration, deduplication, error handling, import count SnackBar
- **App icon**: generated — dark navy background, 3 coloured stacked bars with checkmarks
- **Splash screen**: dark navy (#1A1A2E) via `@color/splash_background` resource in both drawables
- **Build verification**: `flutter analyze` (0 errors) + `flutter build apk --debug` ✅

---

## ✅ Phase 5 — Enhancements
- **Goal/Project Feature**:
  - `Goal` entity and `GoalsTable` (Drift) with ID, title, type (project/habit/no_time), and durationHours.
  - Linked Tasks to Goals via `goalId` foreign key.
  - New `GoalFormScreen` to create long term projects with custom durations (years/months/days converted to hours).
  - Updated `TaskFormScreen` with dropdown to select a goal or prompt goal creation.
  - Display associated goal within `TaskCardWidget` directly on the stack timeline.
  - Information tile for Goal in `TaskDetailScreen`.

---

## ✅ Phase 5.5 — UI Polish & Documentation Updates
- **Smooth Sticky Header Refactor**: Converted `TaskCardWidget` to a StatefulWidget that tracks scroll position with mathematical calculations (`cardTopNow = baseline - scrollDelta`) ensuring titles stay centred beautifully in the viewport without lagging or causing `findRenderObject` layout cycle blinks.
- **Database ER Diagram Docs**: Updated project documentation by adding `docs/er-diagram.md`, containing a live-generated Mermaid diagram reflecting the complete Drift schema (Tasks, Tags, Goals, Analytics), schema relationships, and denormalised tag reasoning.

---

## ✅ Phase 6 — Backend API (Node.js + Aiven Postgres)
- **Node.js/Express backend** initialised with dependencies: `express`, `pg`, `bcrypt`, `jsonwebtoken`, `zod`, `cors`, `qrcode`, `uuid`
- **Postgres schema** (`db/schema.sql`): `users`, `groups`, `group_members`, `group_invites` tables
- **DB migration script** (`db/migrate.js`) + connection pool (`db/pool.js`) with SSL + Aiven support
- **Auth routes** (`POST /auth/register`, `POST /auth/login`) with bcrypt hashing + JWT token issuance (7d expiry)
- **User routes** (`GET /users/me`, `PUT /users/me`, `GET /users/:id`) with public/group visibility logic
- **Groups routes** (`GET/POST /groups`, `GET /groups/:id`, `GET /groups/:id/qr`, `POST /groups/join`, `POST /groups/:id/invite`), QR code generation via `qrcode` package
- **Invites routes** (`GET /invites`, `POST /invites/:id/accept`, `POST /invites/:id/reject`) with transactional accept logic
- **JWT auth middleware** (`middleware/auth.js`) verifying Bearer tokens on all protected routes
- **Security hardening**:
  - `helmet` for HTTP security headers
  - Global rate limiter: 100 req / 15 min per IP
  - Auth-specific rate limiter: 10 req / 15 min per IP
  - Configurable CORS via `ALLOWED_ORIGINS` env var
  - JSON body limit: 50 KB
  - 404 + global error handler middleware
- **`/cron-job` keep-alive endpoint**: `GET /cron-job` → 200 OK (for Render free tier wake-up pings)
- **`backend/.gitignore`**: excludes `node_modules/`, `.env`, logs, `.DS_Store`, IDE files
- **`render.yaml`**: Render hosting config — `rootDir: backend`, `buildCommand: npm ci`, `startCommand: node server.js`; secrets set via Render dashboard

---


## 📊 Build Summary (v1.0)
| Check | Result |
|---|---|
| `flutter analyze` | ✅ 0 errors |
| `flutter build apk --debug` | ✅ `app-debug.apk` |
| GitHub Actions CI | ✅ Configured |
| Tests | ✅ Domain unit + widget + integration scaffold |

---

## ✅ Phase 7 — Flutter Cloud Integration: Auth
- **Dependencies**: `dio ^5.7.0`, `flutter_secure_storage ^9.2.2` added to `pubspec.yaml`
- **`AppConfig.apiBaseUrl`**: compile-time constant, defaults to `https://taskstack-api.onrender.com`
- **`ApiClient`** (`lib/core/network/api_client.dart`): singleton Dio with JWT Bearer interceptor (reads token from secure storage on every request)
- **`AuthUser` entity** (`domain/entities/auth_user.dart`): `fromJson`/`toJson` for secure storage persistence
- **`AuthRepository` interface** + **`AuthRepositoryImpl`**: login, register, logout, token persistence in `flutter_secure_storage`
- **`AuthNotifier`** (sealed `AuthState`: Initial/Loading/Authenticated/Unauthenticated): restores session on cold start, exposes `currentUserProvider`
- **`LoginScreen`**: email + password, validation, loading, error snackbar
- **`SignupScreen`**: username (regex), display name, email, password (min 8)
- **GoRouter auth guard**: redirects unauthenticated users to `/login`, prevents double-navigation during `AuthInitial`
- **Android `INTERNET` permission** added to `AndroidManifest.xml`

---

## ✅ Phase 8 — Flutter Cloud Integration: Groups & Invites
- **Dependencies**: `mobile_scanner ^5.2.3`, `qr_flutter ^4.1.0` added
- **`Group` + `GroupMember` + `Invite` entities** with `fromJson` factories
- **`GroupRepository` interface** + **`GroupRepositoryImpl`**: all `/groups` and `/invites` endpoints via authenticated Dio
- **`GroupNotifier`**: `AsyncValue<List<Group>>` state, `create`/`join`/`inviteByUsername` methods
- **`InviteNotifier`**: `AsyncValue<List<Invite>>`, `accept`/`reject`, `pendingCount` getter
- **`groupDetailProvider` + `groupQrProvider`**: auto-dispose family FutureProviders
- **`GroupsListScreen`**: pending invite badge, pull-to-refresh, empty state, dual FAB (scan/create), inline invite bottom sheet with accept/reject
- **`CreateGroupScreen`**: name + description form
- **`GroupDetailScreen`**: members list with roles, invite-by-username dialog, QR button
- **`InviteScreen`**: renders base64 QR image from API (`Image.memory`)
- **`JoinGroupScreen`**: tabbed — QR scanner (`mobile_scanner`, parses `taskstack://join?code=XXX`) + manual code entry
- **Android `CAMERA` permission** added

---

## ✅ Phase 9 — Flutter Cloud Integration: Profiles
- **`UserProfile` entity** with `fromJson`
- **`ProfileRepository`**: `GET /users/me`, `PUT /users/me`, `GET /users/:id`
- **`myProfileProvider` + `userProfileProvider`**: auto-dispose FutureProviders
- **`MyProfileScreen`**: avatar, @username, editable display name/bio/avatarUrl, isPublic toggle, logout button
- **`UserProfileScreen`**: avatar, name, public/private badge, bio card, graceful "Profile is private" lock state

---

## ✅ Navigation & Shell (Phase 7-9 Changes)
- **`AppShell`**: added **Social** tab (index 2, `group`/`group_outlined` icons); Analytics → 3, Settings → 4
- **`AppRouter`**: dual-guard (onboarding + auth), all new routes: `/login`, `/signup`, `/social`, `/groups/new`, `/groups/join`, `/groups/:id`, `/groups/:id/qr`, `/profile/me`, `/profile/:id`

---

## 📊 Build Summary (v1.0 Cloud)
| Check | Result |
|---|---|
| `dart analyze` (new files) | ✅ 0 errors, 0 warnings |
| Backend live at | ✅ `https://taskstack-api.onrender.com` |
| Android permissions | ✅ CAMERA, INTERNET added |
| Auth | ✅ Login/Register/JWT/Secure storage |
| Groups | ✅ CRUD, QR invite, scanner, accept/reject |
| Profiles | ✅ View/edit self, view others with privacy guard |

> **Scope note:** Cloud schema only covers `users`, `groups`, `group_members`, `group_invites`.
> Local tasks/goals are **not yet synced** to cloud (Phase 10). Guest mode (no account) **not yet implemented** (Phase 11).

---

## ✅ Security Audit & Hardening (Post Phase 9)
- **bcrypt** password hashing with 12 rounds confirmed on all auth routes
- **JWT** signed with HS256, 7-day expiry, `sub` claim enforced on all protected routes
- **JWT_SECRET** upgraded from weak placeholder to 96-char `crypto.randomBytes(48)` hex key in `.env`
- **helmet** HTTP security headers on all responses
- **Rate limiting**: global 100 req/15 min; auth routes 10 req/15 min
- **CORS** restricted to `ALLOWED_ORIGINS` env var (not wildcard)
- **SQL injection**: all queries use parameterised `$1…$n` (no string concatenation)
- **Authorization**: groups, invites, and user-update routes all validate `req.user.sub` ownership
- **Body limit**: 50 kb JSON cap
- **`password_hash` never returned** in any API response

---

## ✅ Profile Seed (abhay_byte)
- Registered `abhay_byte` / `abhay02delhi@gmail.com` on live production API
- Display name: Abhay, bio: "Builder of TaskStack", `is_public: true`
- Password: `TaskStack@2026`

---

## ✅ ER Diagram Updated (v4)
- `docs/er-diagram.md` now covers both schemas:
  - **Local** (Drift/SQLite): goals, tasks, tags, daily_summaries
  - **Cloud** (Postgres): users, groups, group_members, group_invites, with Mermaid ERD + relationships table
- Pushed as commit `3be839c`

---

## ✅ Phase 10 — Task Cloud Sync

### Backend
- **`goals` table** added to Postgres schema: `id` (TEXT PK matching Drift UUID), `user_id`, `title`, `type`, `duration_hours`, `created_at`, `updated_at`; indexed on `user_id`
- **`tasks` table** added: all Drift `TasksTable` columns mirrored (`tags_json`, `recurrence_type`, `task_date` as DATE, etc.); indexed on `(user_id)` and `(user_id, task_date)`
- **`backend/routes/tasks.js`**: six endpoints, all protected by `verifyToken`:
  - `GET /tasks?since=<ISO>` — fetch all tasks for user (optional since-filter)
  - `POST /tasks/bulk` — upsert array with **last-write-wins** on `updated_at`
  - `DELETE /tasks/:id` — hard-delete (ownership enforced)
  - `GET /tasks/goals`, `POST /tasks/goals/bulk`, `DELETE /tasks/goals/:id` — same pattern for goals
- **`backend/server.js`** — `app.use('/tasks', tasksRoutes)` registered
- **Aiven Postgres migration** — `node db/migrate.js` applied schema successfully ✅

### Flutter — Sync Layer (`lib/features/sync/`)
- **`sync_repository.dart`** — `SyncRepository` abstract interface + `SyncStatus` enum (`idle`/`syncing`/`error`) + `syncStatusProvider` (`StateProvider`)
- **`sync_repository_impl.dart`** — `SyncRepositoryImpl`:
  - `pushLocalToCloud()`: reads all local goals + tasks from DAOs, bulk-POSTs to API
  - `pullCloudToLocal()`: fetches all remote goals + tasks, upserts into Drift via `InsertMode.replace`
  - Offline-safe: any `DioException` or uncaught error → `SyncStatus.error` (silent, no crash)
- **`sync_status_indicator.dart`** — `ConsumerWidget` in app bar: hidden when idle, `CircularProgressIndicator` when syncing, `cloud_off_rounded` icon (tap-to-retry `pushLocalToCloud`) when error

### Flutter — TaskDao Extensions
- `getAllTasks()` — full-table scan for sync push
- `upsertTask(TasksTableCompanion)` — `InsertMode.replace` for sync pull

### Flutter — Wiring
- **`AuthNotifier`**: `pullCloudToLocal()` fired on login + session restore; `pushLocalToCloud()` fired on register
- **`TaskFormNotifier`**: `pushLocalToCloud()` fired after every successful task save (create or update)
- **`TaskStackScreen` app bar**: `SyncStatusIndicator` added to `actions`

### Verification
- `flutter analyze` → **0 errors, 0 warnings** in all new `sync/` files ✅
- Aiven migration → `✅ Schema applied successfully.` ✅

> **Scope note updated:** Cloud schema now covers `users`, `groups`, `group_members`, `group_invites`, **`goals`**, **`tasks``.
> Guest mode implemented in Phase 11.

---

## ✅ Phase 11 — Guest Mode (Local-Only without Account)

Users can now use TaskStack fully offline without creating an account.

### Auth Layer
- **`AuthGuest`** sealed class added to `AuthState` hierarchy
- **`continueAsGuest()`** method in `AuthNotifier`: sets `isGuestModeProvider` to `true`, emits `AuthGuest`
- **`isGuestModeProvider`** (`StateProvider<bool>`) in `lib/core/providers/guest_mode_provider.dart` — no circular import issues
- **`isGuestProvider`** (`Provider<bool>`) derived from `authNotifierProvider` in `auth_provider.dart`
- **`logout()`** resets `isGuestModeProvider` to `false`

### Login Screen
- **"Continue as Guest" `TextButton.icon`** added below sign-up link with divider separator
- Calls `authNotifierProvider.notifier.continueAsGuest()` — GoRouter redirect immediately grants access

### Router
- `AuthGuest` treated same as `AuthAuthenticated` in the redirect guard (`loggedIn = AuthAuthenticated || AuthGuest`)
- Guests can access all app-shell routes; `/social` itself handles the gate

### Sync Gate
- `SyncRepositoryImpl.pushLocalToCloud()` and `pullCloudToLocal()` both early-return when `isGuestModeProvider` is `true`
- No 401 errors, no `SyncStatus.error` shown while browsing as guest

### Social Tab Gate
- `GroupsListScreen` checks `isGuestProvider` at the top of `build()`
- If guest: renders a dedicated screen with `cloud_off_rounded` icon, "Sign in to use Social" heading, "Sign In" + "Create an account" buttons

### Offline Banner
- **`MaterialBanner`** shown at the top of `TaskStackScreen` body column when `isGuestProvider` is `true`
- Text: "You're using TaskStack offline" with a "Sign In" action leading to `/login`

### Guest → Account Migration
- `login()` in `AuthNotifier` detects `wasGuest` before switching state
- On successful login from guest: calls `pushLocalToCloud()` to migrate all local tasks/goals to cloud
- On `register()`: already calls `pushLocalToCloud()` (covers guest-to-new-account migration too)

### Build Verification
| Check | Result |
|---|---|
| `flutter analyze` | ✅ 0 errors (90 pre-existing infos, unchanged) |
| `flutter build apk --debug` | ✅ `app-debug.apk` copied to `/sdcard/Download/taskstack-debug.apk` |
| Commit | ✅ `c1ba36b` |
