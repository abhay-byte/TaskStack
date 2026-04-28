# Todo Tasks

## ✅ Phase 10: Task Cloud Sync — COMPLETE
- [x] Add `goals` + `tasks` tables to backend Postgres schema (`backend/db/schema.sql`)
- [x] Add backend REST endpoints: `GET /tasks`, `POST /tasks/bulk`, `DELETE /tasks/:id` (same for goals)
- [x] Implement `SyncRepository` in Flutter — `pushLocalToCloud`, `pullCloudToLocal`, last-write-wins on `updated_at`
- [x] `user_id` owner column on all cloud tasks + goals (only user's own data synced)
- [x] Sync trigger: on login → pull cloud→local; on task save → push to cloud (fire-and-forget)
- [x] `SyncStatusIndicator` in app bar — idle (hidden) / spinning / cloud-off error icon (tap to retry)
- [x] Offline-safe — `DioException` caught silently, sets `SyncStatus.error`; retries on next action

## ✅ Phase 11: Guest Mode (Local-Only without Account) — COMPLETE
- [x] Update GoRouter: "Continue as Guest" on `LoginScreen` skips auth guard (`AuthGuest` treated same as authenticated)
- [x] Track `isGuest` via `AuthGuest` sealed state + `isGuestModeProvider` + `isGuestProvider`
- [x] Gate social tab: `GroupsListScreen` shows "Sign in to use Social" UI for guests
- [x] Gate sync: `SyncRepositoryImpl` no-ops on `pushLocalToCloud`/`pullCloudToLocal` when guest
- [x] Show "You're using TaskStack offline" `MaterialBanner` in `TaskStackScreen` for guests
- [x] On login/register from guest: local Drift data pushed to cloud (`pushLocalToCloud` after login, full migration on register)

## ✅ Phase 13: Goals Page Rehaul — COMPLETE
- [x] Update Goal entity — add `iconId`, `graphicImage`, `colorArgb`, `isGoal`
- [x] Update GoalsTable schema + migration to v6
- [x] Update GoalDao — `watchTasksForGoal`, `getTasksForGoalInRange`, `getCommittedMinutesForGoal`
- [x] Update GoalRepository — map new fields, committed-time queries
- [x] Rehaul GoalsListScreen — M3 cards, progress bar, 30-day timeline, "Goals" title
- [x] Rehaul GoalFormScreen — icon picker, colour picker, `isGoal` toggle, "New Goal" title
- [x] Update Firebase sync — push/pull `iconId`, `graphicImage`, `colorArgb`, `isGoal`
- [x] Write tests — DAO (5), repository (6), widgets (10) = 21 new tests, all passing

## 🔄 Current Issue: Sync 500 Error on Sleep Task
- [ ] Investigate and fix 500 error when saving task "Sleep" with daily recurrence, time 11:00 PM to 6:30 AM

## 🔮 Future Enhancements (Post v1.0)
- Signed release APK (requires keystore — manual step)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
