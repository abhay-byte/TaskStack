# TaskStack — Entity-Relationship Diagram

> **Two schemas coexist in TaskStack:**
> - **Local (SQLite / Drift)** — offline task data on-device
> - **Cloud (Postgres / Aiven)** — auth, social groups, and profiles

---

## Local Schema (SQLite via Drift)

> Source: `lib/database/tables/` + `lib/database/app_database.dart` (schema v5).

```mermaid
erDiagram

    goals {
        TEXT     id              PK
        TEXT     title           "max 80 chars"
        TEXT     type            "default: project"
        INT      durationHours   "nullable — no set time if null"
        DATETIME createdAt
        DATETIME updatedAt       "last-write-wins sync timestamp"
    }

    tasks {
        TEXT     id                       PK
        TEXT     title                    "max 80 chars"
        TEXT     description              "nullable"
        TEXT     purpose                  "nullable"
        TEXT     iconId                   "nullable"
        INT      colorArgb                "nullable"
        TEXT     graphicImage             "nullable — SVG asset path"
        TEXT     tagsJson                 "JSON array of tag strings, default []"
        INT      startMinutes             "nullable — minutes from midnight"
        INT      durationMinutes          "nullable"
        TEXT     recurrenceType           "none|daily|weekly|…, default none"
        TEXT     recurrenceRule           "nullable — RRULE / custom days"
        INT      repeatIntervalMinutes    "nullable"
        BOOL     notificationEnabled      "default true"
        INT      notificationOffsetMinutes "default 5"
        TEXT     status                   "pending|done, default pending"
        DATETIME completedAt              "nullable"
        DATETIME createdAt
        DATETIME updatedAt
        TEXT     parentTaskId             "nullable — FK → tasks.id"
        TEXT     goalId                   "nullable — FK → goals.id"
        TEXT     taskDate                 "yyyy-MM-dd"
    }

    tags {
        TEXT     id        PK
        TEXT     name      "max 50 chars, UNIQUE"
        INT      colorArgb "nullable"
        DATETIME createdAt
    }

    daily_summaries {
        TEXT  taskDate                  PK  "yyyy-MM-dd"
        INT   totalScheduled                "default 0"
        INT   totalCompleted                "default 0"
        INT   totalDurationPlanned          "default 0 (minutes)"
        INT   totalDurationCompleted        "default 0 (minutes)"
        REAL  productivityScore             "nullable 0.0–1.0"
        TEXT  tagBreakdownJson              "JSON map tag→minutes, default {}"
    }

    deleted_tasks {
        TEXT     id         PK  "task id tombstone"
        DATETIME deletedAt      "UTC delete marker for cloud sync"
    }

    goals ||--o{ tasks : "has"
    tasks ||--o{ tasks : "parent of (recurring instances)"
```

---

## Cloud Schema (Postgres / Aiven)

> Source: `backend/db/schema.sql`. Powered by `pgcrypto` UUIDs.

```mermaid
erDiagram

    users {
        UUID        id            PK  "gen_random_uuid()"
        TEXT        username          "UNIQUE NOT NULL"
        TEXT        email             "UNIQUE NOT NULL"
        TEXT        password_hash     "bcrypt, NOT NULL"
        TEXT        display_name      "nullable"
        TEXT        bio               "nullable, max 280"
        TEXT        avatar_url        "nullable"
        BOOL        is_public         "default false"
        TIMESTAMPTZ created_at        "default now()"
    }

    groups {
        UUID        id            PK  "gen_random_uuid()"
        TEXT        name              "NOT NULL"
        TEXT        description       "nullable"
        UUID        created_by        "FK → users.id SET NULL"
        TEXT        invite_code       "UNIQUE, 12-hex default"
        TIMESTAMPTZ created_at        "default now()"
    }

    group_members {
        UUID        group_id      PK  "FK → groups.id CASCADE"
        UUID        user_id       PK  "FK → users.id CASCADE"
        TEXT        role              "owner|member, default member"
        TIMESTAMPTZ joined_at         "default now()"
    }

    group_invites {
        UUID        id            PK  "gen_random_uuid()"
        UUID        group_id          "FK → groups.id CASCADE"
        UUID        invited_by        "FK → users.id CASCADE"
        UUID        invited_user_id   "FK → users.id CASCADE"
        TEXT        status            "pending|accepted|rejected"
        TIMESTAMPTZ created_at        "default now()"
    }

    goals {
        TEXT        id            PK  "UUID string — matches Drift id"
        UUID        user_id           "FK → users.id CASCADE"
        TEXT        title             "NOT NULL"
        TEXT        type              "project|habit|noTime, default project"
        INT         duration_hours    "nullable"
        TIMESTAMPTZ created_at        "default now()"
        TIMESTAMPTZ updated_at        "default now()"
    }

    tasks {
        TEXT        id                          PK  "UUID string — matches Drift id"
        UUID        user_id                         "FK → users.id CASCADE"
        TEXT        title                           "NOT NULL"
        TEXT        description                     "nullable"
        TEXT        purpose                         "nullable"
        TEXT        icon_id                         "nullable"
        INT         color_argb                      "nullable"
        TEXT        tags_json                       "JSON array, default []"
        INT         start_minutes                   "nullable"
        INT         duration_minutes                "nullable"
        TEXT        recurrence_type                 "none|daily|weekly|…, default none"
        TEXT        recurrence_rule                 "nullable"
        INT         repeat_interval_minutes         "nullable"
        BOOL        notification_enabled            "default true"
        INT         notification_offset_minutes     "default 5"
        TEXT        status                          "pending|done, default pending"
        TIMESTAMPTZ completed_at                    "nullable"
        DATE        task_date                       "NOT NULL"
        TEXT        parent_task_id                  "nullable — self-ref"
        TEXT        goal_id                         "nullable — FK → goals.id SET NULL"
        TIMESTAMPTZ created_at                      "default now()"
        TIMESTAMPTZ updated_at                      "default now()"
    }

    users      ||--o{ groups         : "creates"
    users      ||--o{ group_members  : "belongs to"
    groups     ||--o{ group_members  : "has"
    users      ||--o{ group_invites  : "sends / receives"
    groups     ||--o{ group_invites  : "has pending"
    users      ||--o{ goals          : "owns"
    users      ||--o{ tasks          : "owns"
    goals      ||--o{ tasks          : "has"
    tasks      ||--o{ tasks          : "parent of (recurring instances)"
```

---

## Relationships & Notes

### Local (Drift / SQLite)

| Relationship | Type | Description |
|---|---|---|
| `goals` → `tasks` | One-to-many | A goal can have many tasks; `tasks.goalId` is a nullable FK |
| `tasks` → `tasks` | Self-referencing | `tasks.parentTaskId` links recurring instances to their template |
| `tasks` ↔ `tags` | Denormalised | Tags stored inline as JSON array (`tagsJson`); `tags` table holds the master tag registry |
| `daily_summaries` | Standalone | Materialised analytics cache keyed by date; no FK |
| `deleted_tasks` | Standalone | Local tombstones preserve deletions until sync pushes `deletedAt` markers to cloud |

### Day Todo View

The Stack page's day-only Todo sheet does **not** introduce a separate todo table.

- Day todos reuse `tasks` rows whose `taskDate` matches the selected calendar day.
- Todo items are simply **unscheduled tasks** (`startMinutes = null`).
- Because the list is date-scoped, opening the Todo sheet on the next day naturally shows a fresh list for that day.

### Cloud (Postgres / Aiven)

| Relationship | Type | Description |
|---|---|---|
| `users` → `groups` | One-to-many | `groups.created_by` tracks group creator |
| `users` ↔ `groups` | Many-to-many | Via `group_members` pivot (composite PK prevents duplicates) |
| `users` ↔ `group_invites` | One-to-many | Both `invited_by` and `invited_user_id` are user FKs |
| `groups` → `group_invites` | One-to-many | `UNIQUE(group_id, invited_user_id)` prevents duplicate invites |
| `users` → `goals` | One-to-many | `goals.user_id` scopes goals to their owner (CASCADE delete) |
| `users` → `tasks` | One-to-many | `tasks.user_id` scopes tasks to their owner (CASCADE delete) |
| `goals` → `tasks` | One-to-many | `tasks.goal_id` FK mirrors local relationship |
| `tasks` → `tasks` | Self-referencing | `tasks.parent_task_id` links recurring instances to template |

### Tag Storage Strategy

Tags use a **hybrid model**:
- `tags` table — master registry of tag names + colours (tag picker UI)
- `tasks.tagsJson` — denormalised copy of tag strings per task (fast reads, no join)

This means task queries never need a join to retrieve tags, at the cost of tag renames requiring a bulk update across all tasks.

---

## Schema Version History

| Version | Schema | Change |
|---|---|---|
| 1 | Local | Initial: `tasks`, `tags`, `daily_summaries` |
| 2 | Local | Added `tasks.graphicImage` column |
| 3 | Local | Added `goals` table + `tasks.goalId` column |
| 4 | Local | Added `goals.updatedAt` column (last-write-wins sync support) |
| 5 | Local | Added `deleted_tasks` tombstone table for delete sync |
| 6 | Local | Rolling window cleanup: deletes old generated recurring instances (>14 days, pending/uncompleted) |
| 6 | Cloud | Initial cloud schema: `users`, `groups`, `group_members`, `group_invites` |
| 7 | Cloud | Phase 10: added `goals` + `tasks` tables (user-scoped mirrors of Drift schema) |

### Rolling Window Architecture (v6)

**Problem:** Daily recurring tasks generated 365 rows upfront (parent + 364 children), causing:
- Slow creation (batch 366 inserts)
- Large sync payload (~164 KB per daily task)
- Scroll performance degradation with many rows

**Solution:** Rolling 2-week window (7 days back + 14 days forward = 21 days):
- **Creation:** Only parent inserted; no future instances generated
- **Maintenance:** `MaintainRecurringWindowUseCase` populates missing instances on-demand
- **Trimming:** `deleteOldPendingInstances` removes outdated pending rows
- **Lifecycle hooks:** Runs on app startup, every hour while open, after task CRUD

**Implementation:**
```dart
// New DAO methods
Future<List<TasksTableData>> getRecurringParents();
Future<List<String>> getInstanceDatesInRange(String parentId, String from, String to);
Future<int> deleteOldPendingInstances(String parentId, String beforeDate);

// New use case
class MaintainRecurringWindowUseCase {
  static const _windowBackDays = 7;
  static const _windowForwardDays = 14;
  // ...
}
```
