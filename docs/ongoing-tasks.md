# Ongoing Tasks

## ✅ Phase 10: Task Cloud Sync — COMPLETE

Bidirectional sync between local Drift/SQLite and cloud Postgres is now live.

**What was built:**
- **Backend**: `goals` + `tasks` tables added to Postgres schema (user-scoped). New `/tasks` router with `GET /tasks`, `POST /tasks/bulk`, `DELETE /tasks/:id` and mirror endpoints under `/tasks/goals`. Schema migrated on Aiven.
- **Flutter sync layer**: `SyncRepository` interface + `SyncRepositoryImpl` (`pushLocalToCloud` / `pullCloudToLocal`). Conflict resolution: last-write-wins on `updated_at`. Offline-safe via `DioException` catch.
- **Wiring**: pull triggered on login + session restore; push triggered on every task save. `SyncStatusIndicator` in app bar (idle=hidden, syncing=spinner, error=cloud-off tap-to-retry).

---

## ✅ Phase 11: Guest Mode — COMPLETE

All guest mode features shipped in commit `c1ba36b`. See `finished-tasks.md` for details.

---

## ✅ Sync 500 Error on Sleep Task — RESOLVED

**Problem:** Sync failed with 500 error when saving a task called "Sleep" with:
- Daily recurrence
- Start time: 11:00 PM (1380 minutes from midnight)
- End time: 6:30 AM (390 minutes from midnight)
- Duration: 7.5 hours (450 minutes)

**Root Cause:** The backend's `/tasks/bulk` endpoint tried to insert all tasks in a single large SQL query. When users create daily recurring tasks, the app generates 365 instances, causing the SQL query to exceed PostgreSQL's query size limits, resulting in 500 Internal Server Error.

**Fix:** Modified the backend to process tasks in smaller batches of 50 at a time:
- Added `_upsertTaskBatch()` helper function for tasks
- Added `_upsertGoalBatch()` helper function for goals
- Both bulk endpoints now loop through data in batches of 50

This allows syncing daily recurring tasks (365 instances) without hitting query size limits.

---

## 🔄 Current Issues

### Issue 1: Intermittent 500 Error on First Sync — RESOLVED
**Problem:** Creating a task gives 500 error on first sync attempt but succeeds on retry.

**Root Cause:** Cold start issue with Render's free tier - server not ready on first request.

**Fix:** Added retry logic with exponential backoff in Flutter sync code (`_pushTasksWithRetry`) to automatically retry on 500 errors.

### Issue 2: Custom Recurrence Bug - Wrong Days Added — RESOLVED
**Problem:** When selecting Monday-Friday as recurrence, task incorrectly appeared on Saturday (not selected).

**Root Cause:** The `watchTasksForDate` query in SQLite has spill-over logic to show overnight tasks (like Sleep) on the next day. However, this was incorrectly applying to PARENT recurring tasks too. When a user created a Mon-Fri recurring task on Friday at 11 PM with 7.5 hour duration, the parent task (stored with taskDate=Friday) was showing on Saturday due to spill-over.

**Fix:** Modified `task_dao.dart` to exclude parent recurring tasks from spill-over logic. Parent tasks have `recurrenceType != 'none'` AND `parentTaskId == null`. Now only generated instances (which have `parentTaskId` set) will spill over, not the parent task itself.

---

## � Up Next: Future Enhancements (Post v1.0)

- Signed release APK (requires keystore — manual step)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
