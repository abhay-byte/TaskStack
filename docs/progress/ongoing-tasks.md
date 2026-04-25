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

### Issue 6: Deleted Tasks Reappeared After Sign-Out / Sign-In — RESOLVED
**Problem:** Deleting a task removed it locally, but sync only ever upserted task documents to Firestore. Since deletes were never propagated, signing out and back in would pull the old cloud task back onto the device.

**Fix:**
- Added a local `deleted_tasks` tombstone table in Drift/SQLite migration `schemaVersion = 5`.
- Task deletes now record tombstones before removing the local row.
- Sync push now sends tombstones to Firestore as `deletedAt` markers.
- Sync pull now treats `deletedAt` as authoritative and removes the local task instead of restoring it.
- Local tombstones are cleared once their delete has been pushed successfully.

This preserves deletions across sign-out/sign-in without risking a fresh login wiping cloud data.

---

### Issue 7: Task Delete Tombstones Were Not Pushed Immediately — RESOLVED
**Problem:** Even after adding delete tombstones, task deletion itself did not trigger a sync push. If the user refreshed or signed back in before another save happened, pull could still resurrect the deleted cloud task.

**Fix:** `DeleteTaskUseCase` now triggers `pushLocalToCloud()` immediately after local deletion succeeds, so task tombstones reach Firestore right away instead of waiting for a later unrelated save.

---

## ✅ Phase 12: Delete Account — COMPLETE

**What was built:**
- **Backend `DELETE /auth/account`**: Authenticated endpoint that deletes the user and all associated data (tasks, goals, group memberships, invites) in a single Postgres transaction with rollback on failure. Route: `DELETE /auth/account` (requires `Authorization: Bearer <token>`).
- **Backend `GET /auth/delete-account`**: Public HTML info page served directly from the API. Lists in-app deletion steps, what data is deleted vs. retained, and a contact email fallback. URL: `https://taskstack-api.onrender.com/auth/delete-account` — used as the **Delete Account URL** in Google Play Console under Data Safety.
- **Flutter `AuthRepository.deleteAccount()`**: Added to the abstract interface and implemented in `AuthRepositoryImpl` — calls `DELETE /auth/account` with stored token, then clears secure storage.
- **Flutter `AuthNotifier.deleteAccount()`**: Calls the repository, transitions state to `AuthLoading` → `AuthUnauthenticated`. On error, restores prior authenticated state and rethrows so the UI can show an error snackbar.
- **Settings Screen — Danger Zone section**: A new "Danger Zone" section (shown only for authenticated users) with a red `Delete Account` tile. Tapping it opens a confirmation dialog with a destructive red button. On success, navigates to `/login` with a success toast.

---

## ✅ Stack Day Todo Sheet — COMPLETE

**What was built:**
- Added a `Todo` action on the Stack page that opens a compact day-specific bottom sheet.
- The sheet is scoped to the currently focused stack date and shows only **unscheduled tasks** for that day.
- Users can add quick one-day todo items directly from the sheet without opening the full task form.
- Todo items can be marked done or undone inline from the sheet.
- Completion state changes now push sync immediately, so day-todo updates persist more reliably across refresh/sign-in.

**Data model note:** This feature reuses the existing `tasks` table. Day todos are just tasks with `taskDate = selected day` and `startMinutes = null`, so the list naturally resets when the user opens another day.

---

## ✅ Group Delete by Owner — COMPLETE

**Context:** Users could create groups but had no way to delete them.

**What was built:**
- `GroupRepository.deleteGroup(groupId)` — verifies ownership via `group_members` role check, then cascades:
  1. Deletes the group doc from `groups`
  2. Queries + deletes all `group_members` docs where `groupId == groupId`
  3. Queries + deletes all `invites` docs where `groupId == groupId`
  4. Deletes the invite-code mapping from RTDB `inviteCodes/<code>` (best-effort)
  - Batched into chunks of 400 to stay under Firestore's 500-write batch limit.
- `GroupNotifier.delete(groupId)` — calls repo, then optimistically filters the deleted group out of the local list so the UI updates instantly.
- `GroupsListScreen` — owner group cards now show a `PopupMenuButton` (⋮) with a red "Delete group" item.
- `GroupDetailScreen` — owner app bar now shows a `PopupMenuButton` with "Delete group". After deletion, auto-pops back to the list.
- Both entry points show a Material 3 `AlertDialog` with the group name and a red destructive "Delete" button.

**Trade-offs:** Client-side cascade delete chosen over Cloud Function to avoid Firebase Functions infrastructure for v1.0. Risk of partial delete on crash is acceptable for non-critical group data.

**Verification:**
- `flutter analyze` → 0 new errors (136 pre-existing info/warnings unchanged)
- `flutter run -d CPH2691` → installed and launched successfully on physical device

---

## 🚀 Up Next: Future Enhancements (Post v1.0)

- ~~Signed release APK~~ ✅ Done (keystore at `~/repos/keys/`)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
