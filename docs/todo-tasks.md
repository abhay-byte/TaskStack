# Todo Tasks

## 🔄 Phase 10: Task Cloud Sync
- [ ] Add `tasks` + `goals` + `tags` tables to backend Postgres schema (`backend/db/schema.sql`)
- [ ] Add backend REST endpoints: `POST /tasks`, `GET /tasks`, `PUT /tasks/:id`, `DELETE /tasks/:id` (same for goals)
- [ ] Implement `SyncRepository` in Flutter — `pushLocalToCloud`, `pullCloudToLocal`, `resolveConflicts` (last-write-wins on `updated_at`)
- [ ] Add a `user_id` owner column to cloud tasks (only user's own tasks synced)
- [ ] Wire sync trigger: on login, pull cloud → local; on task create/update/delete (if logged in), push to cloud
- [ ] Show sync status indicator in the app bar (idle / syncing / error)
- [ ] Handle offline gracefully — queue failed sync ops and retry when network returns

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
