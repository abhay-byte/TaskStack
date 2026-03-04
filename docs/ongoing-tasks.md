# Ongoing Tasks

## 🔄 Phase 10: Task Cloud Sync (Next Up)

No sync currently exists between the local Drift/SQLite database (tasks, goals) and the cloud Postgres database (which only handles users, groups, invites).

**Planned approach:**
- Extend backend schema with `tasks` + `goals` tables (user-scoped)
- Implement `SyncRepository` in Flutter with push/pull and last-write-wins conflict resolution
- Trigger: login → pull cloud→local; create/update/delete → push to cloud (when authenticated)
- Offline queue for failed sync ops

## 👤 Phase 11: Guest Mode

Currently the auth guard forces all users to `/login`. Adding a "Continue as Guest" path:

**Planned approach:**
- `isGuest` state in `AuthNotifier`
- Social tab gated (shows sign-in prompt for guests)
- Sync disabled for guests
- Optional: local → cloud migration when guest logs in
