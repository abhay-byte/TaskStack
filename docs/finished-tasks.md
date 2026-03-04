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

## 📊 Build Summary (v1.0)
| Check | Result |
|---|---|
| `flutter analyze` | ✅ 0 errors |
| `flutter build apk --debug` | ✅ `app-debug.apk` |
| GitHub Actions CI | ✅ Configured |
| Tests | ✅ Domain unit + widget + integration scaffold |
