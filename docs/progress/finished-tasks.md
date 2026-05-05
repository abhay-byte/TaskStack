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

---

## ✅ Phase 12 — Bug Fixes (Post-Launch)

### Bug 1: Sync Retry via Cloud-Off Icon Called Pull Instead of Push
**Problem:** After a failed task sync (500 error from server cold-start), tapping the red `cloud_off` icon in the app bar called `pullCloudToLocal()`. This fetched stale data from the cloud, never re-uploading the newly created local task. The "Retry" banner button was already correctly calling `pushLocalToCloud()`, which is why dismissing and retrying via the banner worked.

**Fix:** Updated `sync_status_indicator.dart` — the error state `onPressed` now calls `pushLocalToCloud()`.

### Bug 2: AnimatedGraphic WebView Appeared Blank While Loading
**Problem:** `AnimatedGraphic` returned `const SizedBox()` during the WebView initialisation phase, making the graphic area look empty/broken on `TaskDetailScreen` and `TaskFormScreen` until the SVG finished loading.

**Fix:** Updated `animated_graphic.dart` to show a `Container` with the surface color and a centered `CircularProgressIndicator` while `_isLoading` is `true`.

### Bug 3: RepeatToday Recurrence Had No Overlap Validation
**Problem:** Selecting `repeatToday` with a repeat interval shorter than the task duration (e.g. 15-min interval, 30-min task) silently created overlapping instances without any user feedback.

**Fix:**
- `task_providers.dart` (`TaskFormNotifier.save()`): added guard — returns `false` and sets `state.error` with a descriptive message if `repeatIntervalMinutes < durationMinutes`.
- `task_form_screen.dart`: added an inline `errorContainer` banner that appears immediately below the "Repeat every" row when the interval would cause overlap, before the user even taps Save.

---

## ✅ Phase 13: Goals Page Rehaul

**Problem:** The Goals & Projects page was minimal — no icon/image selection, no time tracking visuals, no 30-day timeline, and the form lacked options for distinguishing goals from projects.

**What was built:**
- **Database**: Schema bumped to v6. Added `icon_id`, `graphic_image`, `color_argb`, `is_goal` columns to `goals` table with migration backfill defaults.
- **Goal entity**: Expanded with `iconId`, `graphicImage`, `colorArgb`, `isGoal` fields.
- **GoalDao**: New queries — `watchTasksForGoal`, `getTasksForGoalInRange`, `getCommittedMinutesForGoal` (sums completed task durations).
- **GoalRepository**: New `watchTasksForGoal` and `getCommittedMinutesForGoal` methods.
- **GoalsListScreen** (M3 redesign):
  - Title: "Goals" (was "Goals & Projects")
  - Cards use `surfaceContainerLow` with 12dp radius
  - Custom icon from Material Symbols + accent colour circle avatar
  - `isGoal` label shows "Project Goal" / "Habit" / "Ongoing Goal" vs "Project"
  - Linear progress bar with committed/total hours, percentage, and "X hrs remaining"
  - 30-day timeline strip: coloured dots for completed tasks, grey for pending, empty for no tasks
- **GoalFormScreen** (M3 redesign):
  - Title: "New Goal" / "Edit Goal"
  - `isGoal` Switch with explanatory helper text
  - Icon picker: 20 curated Material Symbols in a wrap grid
  - Colour picker: 12 M3 semantic accent colours in circular chips
  - Duration fields auto-hide when "Ongoing" type is selected
- **Firebase sync**: `_pushGoals` and `_pullGoals` now sync `iconId`, `graphicImage`, `colorArgb`, and `isGoal` to Firestore.
- **Tests**:
  - `test/database/goal_dao_test.dart` — 5 tests
  - `test/features/task_stack/data/repositories/goal_repository_impl_test.dart` — 6 tests
  - `test/widgets/goals_list_screen_test.dart` — 5 tests
  - `test/widgets/goal_form_screen_test.dart` — 5 tests
  - All 74 tests passing

**Build verification:**
| Check | Result |
|---|---|
| `flutter analyze` | ✅ 0 new errors |
| `flutter test` | ✅ 74 tests passing |
| `flutter build apk --debug` | ✅ `app-debug.apk` |

---

## ✅ Phase 14 — Rolling 2-Week Window + FPS Fix

### Architecture Change: Rolling Window for Recurring Tasks
**Problem:** Creating a daily recurring task inserted 365 rows immediately, causing slow creation, 164 KB sync payloads, and degraded scroll performance.

**Solution:** Rolling 2-week window (7 days back + 14 days forward):
- **CreateTaskUseCase:** Only inserts parent task; no future instance generation
- **MaintainRecurringWindowUseCase:** Populates missing instances on-demand, trims old pending rows
- **Lifecycle hooks:** `TaskStackScreen.initState`, hourly timer, `TaskFormScreen._save`

**Files changed:**
- `task_usecases.dart` — Added `MaintainRecurringWindowUseCase`, removed 365-row generation from `CreateTaskUseCase` and `UpdateTaskUseCase`
- `task_dao.dart` — Added `getRecurringParents()`, `getInstanceDatesInRange()`, `deleteOldPendingInstances()`
- `task_repository.dart` / `task_repository_impl.dart` — Wired new DAO methods
- `task_providers.dart` — Added `maintainRecurringWindowUseCaseProvider`
- `app_database.dart` — Schema v6 migration also runs `_cleanupOldRecurringInstances()`
- `task_stack_screen.dart` — Hooks window maintenance on startup + hourly
- `task_form_screen.dart` — Triggers maintenance after save

### Performance Fix: TaskCardWidget Scroll Effect Removed
**Problem:** Each task card attached an `AnimatedBuilder` to `ScrollPosition`. 30 visible cards = 30 rebuilds per scroll frame, causing FPS drops.

**Fix:** Removed per-card scroll-tracking sticky-header effect entirely. `TaskCardWidget` is now a simple `StatelessWidget` with static `Positioned(top: 0, ...)` content.

**Files changed:**
- `task_card_widget.dart` — Removed `_cardKey`, `_baseCardTop`, `_baseScrollOffset`, `_hasMeasured`, `_scrollPos`, `_measureBaseline()`, `_computeContentOffset()`, `AnimatedBuilder`. Replaced with static positioning.

### Test Coverage
**5 new test files:**
- `test/domain/rolling_window_test.dart` — Core window behavior (390 lines)
- `test/domain/window_edge_cases_test.dart` — 15 numbered edge cases (370 lines)
- `test/domain/sync_offline_test.dart` — Offline/online sync matrix (581 lines)
- `test/widgets/task_form_sync_test.dart` — Widget-level sync integration (247 lines)
- `test/widgets/task_card_widget_test.dart` — Simplified widget tests (200 lines)

**Updated test files:**
- `test/domain/task_creation_usecase_test.dart` — Expects 1 insert for daily/weekly/custom
- `test/domain/task_form_notifier_test.dart` — Expects 1 insert for custom recurrence
- `test/widgets/task_form_screen_test.dart` — Added new repo interface methods
- `test/domain/delete_task_usecase_test.dart` — Added new repo interface methods

### Impact
| Metric | Before | After |
|--------|--------|-------|
| Rows per daily task | 366 | ~21 max |
| Firestore sync payload | ~164 KB | ~450 bytes |
| Scroll rebuilds per frame | O(n) task cards | 0 (static) |
| Create task latency | Slow (batch 366 inserts) | Instant (1 insert) |

