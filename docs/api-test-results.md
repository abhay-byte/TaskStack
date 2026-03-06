# API Test Results

## Full App-Payload Sync Test

**Date:** 2025-07-09  
**Script:** `/tmp/fulltest.py` — mirrors exact payload sent by `sync_repository_impl.dart`  
**API:** `https://taskstack-api.onrender.com`  
**Test user:** `test@taskstack.dev` / `testuser`

### Results: 10/10 PASSED

| # | Method | Endpoint | Status | Notes |
|---|--------|----------|--------|-------|
| 1 | POST | `/tasks/goals/bulk` | ✅ 200 | 2 goals upserted |
| 2 | GET | `/tasks/goals` | ✅ 200 | Goals returned |
| 3 | POST | `/tasks/bulk` | ✅ 200 | 4 tasks upserted |
| 4 | GET | `/tasks` | ✅ 200 | Tasks returned |
| 5 | DELETE | `/tasks/app-task-001` | ✅ 200 | Cleanup |
| 6 | DELETE | `/tasks/app-task-002` | ✅ 200 | Cleanup |
| 7 | DELETE | `/tasks/app-task-003` | ✅ 200 | Cleanup |
| 8 | DELETE | `/tasks/app-task-004` | ✅ 200 | Cleanup |
| 9 | DELETE | `/tasks/goals/app-goal-001` | ✅ 200 | Cleanup |
| 10 | DELETE | `/tasks/goals/app-goal-002` | ✅ 200 | Cleanup |

### Test Payload

**Goals sent:**
```json
[
  { "id": "app-goal-001", "title": "Read every day", "type": "habit", "duration_hours": null, "is_completed": false },
  { "id": "app-goal-002", "title": "Learn Flutter", "type": "project", "duration_hours": 200, "is_completed": false }
]
```

**Tasks sent:**
```json
[
  { "id": "app-task-001", "title": "Plain task no goal", "color_argb": null, "goal_id": null },
  { "id": "app-task-002", "title": "Colored task with goal", "color_argb": 4280391411, "goal_id": "app-goal-002" },
  { "id": "app-task-003", "title": "Task orphan goal_id", "color_argb": 4294198070, "goal_id": "nonexistent-goal-never-synced" },
  { "id": "app-task-004", "title": "Max ARGB color", "color_argb": 4294967295, "goal_id": null }
]
```
> `color_argb` values are unsigned 32-bit (ARGB). `app-task-003` uses a `goal_id` that doesn't exist on the server — verifies that the FK constraint was correctly dropped.

### Bugs Fixed (context)

| Bug | Symptom | Root Cause | Fix |
|-----|---------|------------|-----|
| `color_argb` overflow | 500 on tasks with color | `INT` column max 2.1B; ARGB values up to 4.29B | Changed to `BIGINT`; Dart masks with `& 0xFFFFFFFF` |
| `goal_id` FK violation | 500 when task references un-synced goal | `REFERENCES goals(id)` FK constraint | Dropped FK; `goal_id` is plain `TEXT` |
| `libsqlite3.so not found` | App crash on analytics/task pages | `.so` not extracted from APK | `useLegacyPackaging = true` + `sqlite3_flutter_libs 0.5.41` workaround |

---

## Core Endpoint Suite (18 tests)

All 18 endpoints passed in earlier test run (`/tmp/api_test.py`):

- Auth: register, login, me, update profile, change password, delete account
- Tasks: list, get, create, update, delete, bulk upsert
- Goals: list, get, create, update, delete, bulk upsert
- Groups/invites: covered in full endpoint reference (`docs/api.md`)
