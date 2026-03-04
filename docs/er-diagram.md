# TaskStack — Entity-Relationship Diagram

> **Source of truth:** Generated from the Drift table definitions in  
> `lib/database/tables/` and `lib/database/app_database.dart` (schema v3).

---

## ER Diagram

```mermaid
erDiagram

    goals {
        TEXT   id          PK
        TEXT   title       "max 80 chars"
        TEXT   type        "default: project"
        INT    durationHours   "nullable — no set time if null"
        DATETIME createdAt
    }

    tasks {
        TEXT     id               PK
        TEXT     title            "max 80 chars"
        TEXT     description      "nullable"
        TEXT     purpose          "nullable"
        TEXT     iconId           "nullable"
        INT      colorArgb        "nullable"
        TEXT     graphicImage     "nullable — SVG asset path"
        TEXT     tagsJson         "JSON array of tag strings, default []"
        INT      startMinutes     "nullable — minutes from midnight"
        INT      durationMinutes  "nullable"
        TEXT     recurrenceType   "none|daily|weekly|…, default none"
        TEXT     recurrenceRule   "nullable — RRULE string"
        INT      repeatIntervalMinutes "nullable"
        BOOL     notificationEnabled   "default true"
        INT      notificationOffsetMinutes "default 5"
        TEXT     status           "pending|done, default pending"
        DATETIME completedAt      "nullable"
        DATETIME createdAt
        DATETIME updatedAt
        TEXT     parentTaskId     "nullable — FK → tasks.id"
        TEXT     goalId           "nullable — FK → goals.id"
        TEXT     taskDate         "yyyy-MM-dd"
    }

    tags {
        TEXT     id        PK
        TEXT     name      "max 50 chars, UNIQUE"
        INT      colorArgb "nullable"
        DATETIME createdAt
    }

    daily_summaries {
        TEXT  taskDate              PK  "yyyy-MM-dd"
        INT   totalScheduled            "default 0"
        INT   totalCompleted            "default 0"
        INT   totalDurationPlanned      "default 0 (minutes)"
        INT   totalDurationCompleted    "default 0 (minutes)"
        REAL  productivityScore         "nullable 0.0–1.0"
        TEXT  tagBreakdownJson          "JSON map tag→minutes, default {}"
    }

    goals ||--o{ tasks : "has"
    tasks ||--o{ tasks : "parent of (recurring instances)"
```

---

## Relationships & Notes

| Relationship | Type | Description |
|---|---|---|
| `goals` → `tasks` | One-to-many | A goal can have many tasks; `tasks.goalId` is a nullable FK |
| `tasks` → `tasks` | Self-referencing | `tasks.parentTaskId` links recurring instances to their template |
| `tasks` ↔ `tags` | Denormalised | Tags are stored inline as a JSON array (`tagsJson`); the `tags` table holds the master list of user-defined tags with colours |
| `daily_summaries` | Standalone | Materialised analytics cache keyed by date; computed from `tasks`, no FK |

### Tag Storage Strategy

Tags use a **hybrid model**:
- `tags` table — master registry of tag names + colours (for the tag picker UI)
- `tasks.tagsJson` — denormalised copy of tag strings per task (fast reads, no join)

This means task queries never need a join to retrieve tags, at the cost of tag renames requiring a bulk update across all tasks.

### Recurring Tasks

Recurring instances are created as separate rows each with:
- `parentTaskId` pointing to the original/template task
- Their own `taskDate`
- Their own `status` / `completedAt`

This allows per-instance completion without affecting the template or siblings.

---

## Schema Version History

| Version | Change |
|---|---|
| 1 | Initial: `tasks`, `tags`, `daily_summaries` |
| 2 | Added `tasks.graphicImage` column |
| 3 | Added `goals` table + `tasks.goalId` column |
