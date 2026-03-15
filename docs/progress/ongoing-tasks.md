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

### Issue 3: Sync Cloud-Off Icon Retried Pull Instead of Push — RESOLVED
**Problem:** After a failed task sync (500 error), tapping the cloud-off icon in the app bar would call `pullCloudToLocal()` instead of `pushLocalToCloud()`. This fetched old cloud data without ever pushing the newly created task.

**Fix:** Changed `sync_status_indicator.dart` error state `onPressed` to call `pushLocalToCloud()`. The Retry button in the error banner was already correct.

---

### Issue 4: AnimatedGraphic Showed Blank While Loading — RESOLVED
**Problem:** `AnimatedGraphic` returned `const SizedBox()` during WebView loading, making the graphic slot appear empty/broken on the task form and detail pages.

**Fix:** Replaced the blank `SizedBox()` with a styled container showing a `CircularProgressIndicator` until the SVG WebView finishes loading.

---

### Issue 5: No Overlap Validation for RepeatToday Recurrence — RESOLVED
**Problem:** When selecting `repeatToday` recurrence with a repeat interval shorter than the task duration, the app would silently create overlapping task instances.

**Fix:**
- Added validation in `TaskFormNotifier.save()` — rejects save with an error message if `repeatIntervalMinutes < durationMinutes`.
- Added inline warning banner in `TaskFormScreen` that appears immediately when the user sets a conflicting interval, before they even try to save.

---

## ✅ Phase 12: Delete Account — COMPLETE

**What was built:**
- **Backend `DELETE /auth/account`**: Authenticated endpoint that deletes the user and all associated data (tasks, goals, group memberships, invites) in a single Postgres transaction with rollback on failure. Route: `DELETE /auth/account` (requires `Authorization: Bearer <token>`).
- **Backend `GET /auth/delete-account`**: Public HTML info page served directly from the API. Lists in-app deletion steps, what data is deleted vs. retained, and a contact email fallback. URL: `https://taskstack-api.onrender.com/auth/delete-account` — used as the **Delete Account URL** in Google Play Console under Data Safety.
- **Flutter `AuthRepository.deleteAccount()`**: Added to the abstract interface and implemented in `AuthRepositoryImpl` — calls `DELETE /auth/account` with stored token, then clears secure storage.
- **Flutter `AuthNotifier.deleteAccount()`**: Calls the repository, transitions state to `AuthLoading` → `AuthUnauthenticated`. On error, restores prior authenticated state and rethrows so the UI can show an error snackbar.
- **Settings Screen — Danger Zone section**: A new "Danger Zone" section (shown only for authenticated users) with a red `Delete Account` tile. Tapping it opens a confirmation dialog with a destructive red button. On success, navigates to `/login` with a success toast.

---

## 🚀 Up Next: Future Enhancements (Post v1.0)

- ~~Signed release APK~~ ✅ Done (keystore at `~/repos/keys/`)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
