# Todo Tasks

## ✅ Phase 10: Task Cloud Sync — COMPLETE
- [x] Add `goals` + `tasks` tables to backend Postgres schema (`backend/db/schema.sql`)
- [x] Add backend REST endpoints: `GET /tasks`, `POST /tasks/bulk`, `DELETE /tasks/:id` (same for goals)
- [x] Implement `SyncRepository` in Flutter — `pushLocalToCloud`, `pullCloudToLocal`, last-write-wins on `updated_at`
- [x] `user_id` owner column on all cloud tasks + goals (only user's own data synced)
- [x] Sync trigger: on login → pull cloud→local; on task save → push to cloud (fire-and-forget)
- [x] `SyncStatusIndicator` in app bar — idle (hidden) / spinning / cloud-off error icon (tap to retry)
- [x] Offline-safe — `DioException` caught silently, sets `SyncStatus.error`; retries on next action

## 👤 Phase 11: Guest Mode (Local-Only without Account)
- [ ] Update GoRouter: add "Continue as Guest" option on `LoginScreen` that skips auth guard
- [ ] Track `isGuest` boolean in `AuthNotifier` / `SettingsNotifier`
- [ ] Gate social tab: show "Sign in to use Social" placeholder when in guest mode
- [ ] Gate sync: no push/pull when guest
- [ ] Show "You're using TaskStack offline" banner on guest mode
- [ ] On Sign Up / Login from guest: migrate local Drift data into cloud (optional but ideal)

## 🔮 Future Enhancements (Post v1.0)
- Signed release APK (requires keystore — manual step)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
