# Ongoing Tasks

## ✅ All Current Issues Resolved

All previously tracked issues (Issues 1–7) and Phase 13 changes are now complete. See `finished-tasks.md` for details.

---

---

## ✅ Phase 13: Goals Page Rehaul — COMPLETE

**What was built:**
- **Database schema v6**: Added `icon_id`, `graphic_image`, `color_argb`, `is_goal` columns to `goals` table. Migration handles existing rows with sensible defaults.
- **Goal entity updated**: Added `iconId`, `graphicImage`, `colorArgb`, `isGoal` fields with full `copyWith` support.
- **GoalDao extended**: Added `watchTasksForGoal`, `getTasksForGoalInRange`, and `getCommittedMinutesForGoal` for time-tracking analytics.
- **GoalRepository updated**: New methods for watching linked tasks and fetching committed minutes.
- **GoalsListScreen rehaul** (M3 compliant):
  - Title changed from "Goals & Projects" → "Goals"
  - Goal cards now show custom Material Symbols icon and accent colour
  - Progress bar shows committed hours vs total duration with percentage
  - "X hrs remaining" label below the bar
  - 30-day activity timeline strip per goal (coloured dots = completed tasks, grey = pending, empty = no tasks)
  - Card background uses `surfaceContainerLow` with 12dp radius per M3 spec
- **GoalFormScreen rehaul** (M3 compliant):
  - Title changed from "New Goal/Project" → "New Goal"
  - Added `isGoal` toggle switch with helper text explaining Goal vs Project semantics
  - Added curated Material Symbols icon picker (20 icons in a wrap grid)
  - Added M3 semantic accent colour picker (12 colours matching task palette)
  - Duration fields hidden automatically when "Ongoing" type is selected
- **Firebase sync updated**: `SyncRepositoryImpl._pushGoals()` and `_pullGoals()` now sync `iconId`, `graphicImage`, `colorArgb`, and `isGoal` fields to/from Firestore.
- **Tests added**:
  - `test/database/goal_dao_test.dart` — 5 tests covering new fields, committed minutes, linked tasks, date range queries
  - `test/features/task_stack/data/repositories/goal_repository_impl_test.dart` — 6 tests for CRUD with new fields
  - `test/widgets/goals_list_screen_test.dart` — 5 widget tests for title, empty state, progress bar, custom icon/colour, delete dialog
  - `test/widgets/goal_form_screen_test.dart` — 5 widget tests for icon picker, isGoal switch, ongoing type, icon selection, colour selection
- **Build verification**: `flutter analyze` → 0 new errors; `flutter test` → 74 tests passing (all green)

---

## 🚀 Up Next: Future Enhancements (Post v1.0)

- ~~Signed release APK~~ ✅ Done (keystore at `~/repos/keys/`)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
- Performance: Investigate Drift table-level stream invalidation (completing a task on Monday rebuilds all visible day blocks)
- Performance: Consider splitting `_DayViewBlock` into granular `Consumer`/`Selector` widgets so only changed tasks rebuild
