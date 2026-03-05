# Ongoing Tasks

## ✅ Phase 10: Task Cloud Sync — COMPLETE

Bidirectional sync between local Drift/SQLite and cloud Postgres is now live.

**What was built:**
- **Backend**: `goals` + `tasks` tables added to Postgres schema (user-scoped). New `/tasks` router with `GET /tasks`, `POST /tasks/bulk`, `DELETE /tasks/:id` and mirror endpoints under `/tasks/goals`. Schema migrated on Aiven.
- **Flutter sync layer**: `SyncRepository` interface + `SyncRepositoryImpl` (`pushLocalToCloud` / `pullCloudToLocal`). Conflict resolution: last-write-wins on `updated_at`. Offline-safe via `DioException` catch.
- **Wiring**: pull triggered on login + session restore; push triggered on every task save. `SyncStatusIndicator` in app bar (idle=hidden, syncing=spinner, error=cloud-off tap-to-retry).

---

## � Phase 11: Guest Mode (In Progress)

Currently the auth guard forces all users to `/login`. Adding a "Continue as Guest" path:

**Planned approach:**
- `AuthGuest` sealed class + `continueAsGuest()` in `AuthNotifier`
- Social tab gated (shows sign-in prompt for guests)
- Sync disabled for guests (`SyncRepositoryImpl` checks auth state)
- "You're using TaskStack offline" banner on `TaskStackScreen` for guests
- Local → cloud migration when guest logs in or signs up
