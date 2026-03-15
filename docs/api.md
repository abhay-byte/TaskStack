# TaskStack API — Endpoint Reference

**Base URL:** `https://taskstack-api.onrender.com`  
**Auth:** JWT Bearer token — `Authorization: Bearer <token>`  
**Rate limits:** Auth endpoints: 10 req / 15 min per IP · All others: 100 req / 15 min per IP

---

## Seed / Test User

```
email:    test@taskstack.dev
password: Test1234!
username: testuser
```

---

## Auth

### `POST /auth/register`
Create a new account. Returns a JWT token valid for 7 days.

**No auth required**

**Body:**
```json
{
  "username":    "testuser",
  "email":       "test@taskstack.dev",
  "password":    "Test1234!",
  "displayName": "Test User"
}
```

| Field | Rules |
|-------|-------|
| `username` | 3-30 chars, `[a-zA-Z0-9_]` only |
| `email` | valid email |
| `password` | 8-128 chars |
| `displayName` | optional, max 60 chars |

**201 Created:**
```json
{
  "token": "<jwt>",
  "user": { "id": "...", "username": "testuser", "email": "test@taskstack.dev", "display_name": "Test User", "is_public": false, "created_at": "..." }
}
```

**Errors:** `400` invalid fields · `409` username/email already taken

---

### `POST /auth/login`
Login with email + password. Returns a JWT token.

**No auth required**

**Body:**
```json
{
  "email":    "test@taskstack.dev",
  "password": "Test1234!"
}
```

**200 OK:**
```json
{
  "token": "<jwt>",
  "user": { "id": "...", "username": "testuser", ... }
}
```

**Errors:** `400` invalid body · `401` invalid credentials

---

### `DELETE /auth/account`
Permanently delete the authenticated user's account and all associated data (tasks, goals, group memberships, invites). Executed in a single Postgres transaction with rollback on failure.

**Requires auth**

**200 OK:** `{ "deleted": true }`  
**401** missing/invalid token · **500** database error

---

### `GET /auth/delete-account`
Public HTML page explaining how users can request account deletion. No auth required.

Used as the **Delete Account URL** in Google Play Console (Data Safety section).

**URL:** `https://taskstack-api.onrender.com/auth/delete-account`

**200 OK:** HTML page with:
- Step-by-step in-app deletion instructions
- List of data deleted (tasks, goals, groups, profile)
- List of data retained (local device data)
- Contact email fallback

---

## Users

> All routes require `Authorization: Bearer <token>`

### `GET /users/me`
Get the authenticated user's full profile.

**200 OK:**
```json
{
  "id": "...", "username": "testuser", "email": "test@taskstack.dev",
  "display_name": "Test User", "bio": null, "avatar_url": null,
  "is_public": false, "created_at": "..."
}
```

---

### `PUT /users/me`
Update the authenticated user's profile. All fields optional.

**Body:**
```json
{
  "displayName": "New Name",
  "bio":         "I build things.",
  "avatarUrl":   "https://example.com/avatar.png",
  "isPublic":    true
}
```

**200 OK:** Updated user object.

---

### `GET /users/:id`
Get another user's public profile.

- Owner always has access
- Public profiles visible to all authenticated users  
- Private profiles only visible if you share a group

**200 OK:** User object (no email). **403** if profile is private. **404** if not found.

---

## Goals

> All routes require auth

### `GET /tasks/goals`
Get all goals for the authenticated user.

**Query params:** `?since=<ISO8601>` — only return goals updated after this timestamp

**200 OK:**
```json
[
  { "id": "uuid", "user_id": "...", "title": "Learn Flutter", "type": "project", "duration_hours": 100, "created_at": "...", "updated_at": "..." }
]
```

---

### `POST /tasks/goals/bulk`
Upsert an array of goals (last-write-wins on `updated_at`).

**Body:**
```json
[
  {
    "id":             "uuid-string",
    "title":          "Learn Flutter",
    "type":           "project",
    "duration_hours": 100,
    "created_at":     "2026-03-06T00:00:00.000Z",
    "updated_at":     "2026-03-06T00:00:00.000Z"
  }
]
```

| `type` values | `project` · `habit` · `noTime` |

**200 OK:** `{ "upserted": 1 }`  
**400** if validation fails.

---

### `DELETE /tasks/goals/:id`
Delete a goal by ID. Only deletes goals belonging to the authenticated user.

**200 OK:** `{ "deleted": true }` · **404** not found.

---

## Tasks

> All routes require auth

### `GET /tasks`
Get all tasks for the authenticated user.

**Query params:** `?since=<ISO8601>` — only return tasks updated after this timestamp

**200 OK:**
```json
[
  {
    "id": "uuid", "title": "Morning run", "task_date": "2026-03-06",
    "status": "pending", "color_argb": 4280391411, ...
  }
]
```

---

### `POST /tasks/bulk`
Upsert an array of tasks (last-write-wins on `updated_at`).

**Body:**
```json
[
  {
    "id":                          "uuid-string",
    "title":                       "Morning run",
    "description":                 "Workout details",
    "purpose":                     "Stay fit",
    "icon_id":                     null,
    "color_argb":                  4280391411,
    "tags_json":                   "[]",
    "start_minutes":               360,
    "duration_minutes":            30,
    "recurrence_type":             "none",
    "recurrence_rule":             null,
    "repeat_interval_minutes":     null,
    "notification_enabled":        true,
    "notification_offset_minutes": 5,
    "status":                      "pending",
    "completed_at":                null,
    "task_date":                   "2026-03-09",
    "graphic_image":               "assets/images/task_gym.svg",
    "parent_task_id":              null,
    "goal_id":                     null,
    "created_at":                  "2026-03-09T00:00:00.000Z",
    "updated_at":                  "2026-03-09T00:00:00.000Z"
  }
]
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Required. UUID string matching Drift local ID |
| `title` | string | Required. Max 300 chars |
| `description` | string\|null | Optional |
| `purpose` | string\|null | Optional |
| `icon_id` | string\|null | Optional |
| `color_argb` | number\|null | Unsigned 32-bit ARGB integer (stored as `BIGINT`) |
| `tags_json` | string | JSON array string, defaults to `"[]"` |
| `start_minutes` | int\|null | Minutes from midnight |
| `duration_minutes` | int\|null | Task duration in minutes |
| `recurrence_type` | string | `"none"`, `"repeatToday"`, `"daily"`, `"weekly"`, `"custom"` |
| `recurrence_rule` | string\|null | Comma-separated weekday numbers for custom recurrence |
| `repeat_interval_minutes` | int\|null | For `repeatToday` recurrence |
| `notification_enabled` | boolean | Defaults to `true` |
| `notification_offset_minutes` | int | Reminder offset, defaults to `5` |
| `status` | string | `"pending"` or `"done"` |
| `completed_at` | ISO8601\|null | Set when status becomes `"done"` |
| `task_date` | string | Required. `YYYY-MM-DD` format |
| `graphic_image` | string\|null | Asset path, e.g. `"assets/images/task_gym.svg"` |
| `parent_task_id` | string\|null | References the root recurring task ID |
| `goal_id` | string\|null | References a goal (no FK enforced on cloud) |
| `created_at` | ISO8601 | Required |
| `updated_at` | ISO8601 | Required. Used for last-write-wins conflict resolution |

**200 OK:** `{ "upserted": 1 }`  
**400** if validation fails.

> **Bug fix (2026-03-09):** SQL parameter placeholders were generated as bare integers (`1,2,3`) instead of `$1,$2,$3`, causing all bulk upserts to return 500. Fixed in commit `5c96b10`. Also removed duplicate `_upsertTaskBatch` function.

> **Bug fix (2026-03-11):** `GoalsTable` and `Goal` entity were missing an `updatedAt` field. The sync code mirrored `createdAt` as `updated_at`, so the backend's last-write-wins guard (`WHERE EXCLUDED.updated_at > goals.updated_at`) silently rejected every re-sync after the first insert — goal edits never reached the cloud. Fixed by adding `updatedAt` to the local schema (migration v4), updating sync push/pull to use the real timestamp, and triggering `pushLocalToCloud()` after goal create/edit/delete.

> **Bug fix (2026-03-12):** Migration v4 crashed on existing devices with `SqliteException(1): Cannot add a NOT NULL column with default value NULL`. Drift's `m.addColumn()` emits no `DEFAULT` clause, which SQLite rejects for `NOT NULL` columns on existing tables. Fixed by replacing `m.addColumn()` with a raw `customStatement('ALTER TABLE "goals" ADD COLUMN "updated_at" INTEGER NOT NULL DEFAULT 0')` followed by a backfill `UPDATE` from `created_at`.


---

### `DELETE /tasks/:id`
Delete a task by ID. Only deletes tasks belonging to the authenticated user.

**200 OK:** `{ "deleted": true }` · **404** not found.

---

## Groups

> All routes require auth

### `GET /groups`
List all groups the authenticated user is a member of.

**200 OK:**
```json
[
  { "id": "...", "name": "Study Group", "description": "...", "invite_code": "a1b2c3d4e5f6", "role": "owner", "joined_at": "..." }
]
```

---

### `POST /groups`
Create a new group. The creator is automatically added as `owner`.

**Body:**
```json
{ "name": "Study Group", "description": "Optional description" }
```

**201 Created:** `{ "id": "...", "name": "Study Group", "invite_code": "a1b2c3d4e5f6", ... }`

---

### `GET /groups/:id`
Get group details including member list. Only members can view.

**200 OK:**
```json
{
  "id": "...", "name": "Study Group", "invite_code": "a1b2c3d4e5f6",
  "members": [
    { "id": "...", "username": "testuser", "display_name": "Test User", "role": "owner", "joined_at": "..." }
  ]
}
```

**403** not a member.

---

### `GET /groups/:id/qr`
Get a base64 QR code image for the group's invite code. Only members can access.

**200 OK:**
```json
{
  "invite_code": "a1b2c3d4e5f6",
  "qr_base64":   "data:image/png;base64,..."
}
```

The QR encodes: `taskstack://join?code=<invite_code>`

---

### `POST /groups/join`
Join a group using an invite code (e.g. scanned from QR).

**Body:** `{ "invite_code": "a1b2c3d4e5f6" }`

**200 OK:** `{ "success": true, "group_id": "..." }` · **404** invalid code · **400** already a member.

---

### `POST /groups/:id/invite`
Invite another user to the group by username.

**Body:** `{ "username": "friend123" }`

**201 Created:** `{ "id": "...", "status": "pending", "created_at": "..." }`  
**403** not a member · **404** user not found · **409** invite already pending.

---

## Invites

> All routes require auth

### `GET /invites`
List all pending invites for the authenticated user.

**200 OK:**
```json
[
  {
    "id": "...", "status": "pending", "created_at": "...",
    "group_id": "...", "group_name": "Study Group",
    "inviter_id": "...", "inviter_username": "testuser"
  }
]
```

---

### `POST /invites/:id/accept`
Accept a pending invite. User is added to the group as `member`.

**200 OK:** `{ "success": true, "group_id": "..." }` · **404** invite not found/expired.

---

### `POST /invites/:id/reject`
Reject a pending invite.

**200 OK:** `{ "success": true }` · **404** invite not found.

---

## Health / Utility

### `GET /`
Health check — no auth required.

**200 OK:** `{ "service": "TaskStack API", "status": "online" }`

---

### `GET /cron-job`
Keep-alive endpoint for external cron pinger (cron-job.org). Returns `200` with no body. No auth required.

---

## curl Quick-Start

```bash
BASE="https://taskstack-api.onrender.com"

# 1. Login
TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  --data-raw '{"email":"test@taskstack.dev","password":"Test1234!"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

AUTH="-H \"Authorization: Bearer $TOKEN\""

# 2. Get profile
curl -s $BASE/users/me -H "Authorization: Bearer $TOKEN"

# 3. Bulk upsert a task
curl -s -X POST $BASE/tasks/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data-raw '[{"id":"test-001","title":"Test Task","task_date":"2026-03-06","recurrence_type":"none","tags_json":"[]","notification_enabled":true,"notification_offset_minutes":5,"status":"pending","created_at":"2026-03-06T00:00:00.000Z","updated_at":"2026-03-06T00:00:00.000Z"}]'

# 4. Get all tasks
curl -s $BASE/tasks -H "Authorization: Bearer $TOKEN"

# 5. Create a group
curl -s -X POST $BASE/groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data-raw '{"name":"My Group"}'
```
