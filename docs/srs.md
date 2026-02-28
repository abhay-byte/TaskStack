# TaskStack — Software Requirements Specification (SRS)

**Document Version:** 1.0  
**Date:** 2026-02-28  
**Project:** TaskStack — Advanced Daily Task Management & Analytics App  
**Platform:** Flutter (Android & iOS)  
**Status:** Draft

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [User Classes and Characteristics](#3-user-classes-and-characteristics)
4. [System Features & Functional Requirements](#4-system-features--functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [Data Requirements](#7-data-requirements)
8. [Constraints & Assumptions](#8-constraints--assumptions)
9. [Appendix — Glossary](#9-appendix--glossary)

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) document defines the complete set of functional, non-functional, and interface requirements for **TaskStack** version 1.0. It serves as the authoritative reference for all design, development, and testing decisions made during the project lifecycle.

### 1.2 Document Conventions
- **SHALL** — A mandatory requirement that must be implemented in v1.0.
- **SHOULD** — A highly recommended requirement; omission requires justification.
- **MAY** — An optional requirement that can be deferred to a future release.
- Requirements are tagged with unique identifiers: `[FR-XXX]` (Functional), `[NFR-XXX]` (Non-Functional), `[IR-XXX]` (Interface).

### 1.3 Intended Audience
- Product Manager & Project Owner
- UI/UX Designers
- Flutter Developers (frontend & backend)
- QA Engineers
- Stakeholders & Investors

### 1.4 Project Scope
TaskStack is a mobile-first application that provides users with:
- A real-time 24-hour visual task timeline (the "Stack")
- Intelligent repeating task management
- Precise, task-level push notifications
- Rich task customisation (title, description, purpose, tags, icon, time frame)
- Multi-horizon analytics (daily, weekly, monthly, yearly)
- An offline-first architecture with optional cloud backup

### 1.5 References
- TaskStack Problem Statement v1.0
- Flutter SDK documentation (docs.flutter.dev)
- ISO/IEC 29148:2018 — Systems and software engineering — Requirements engineering

---

## 2. Overall Description

### 2.1 Product Perspective
TaskStack is a standalone mobile application. It is not a component of a larger enterprise system. It runs natively on Android (SDK ≥ 21 / Android 5.0) and iOS (≥ 14.0) through the Flutter cross-platform framework. It operates in an offline-first mode, storing all data locally, with an optional cloud synchronisation feature.

### 2.2 Product Functions (High-Level)

```
TaskStack
├── 24-Hour Stack (Home Screen)
│   ├── Infinite-scroll timeline
│   ├── Current-time indicator
│   ├── Task cards (pending / in-progress / done)
│   └── Quick-add floating action button
├── Task Management
│   ├── Create / Edit / Delete tasks
│   ├── Time frame (start + duration)
│   ├── Repeat within today
│   ├── Recurrence (daily / weekly / custom)
│   ├── Rich metadata (title, description, purpose, icon, tags)
│   └── Intentional completion marking
├── Notifications
│   ├── Per-task notification scheduling
│   ├── Custom offset (e.g. 5 min before start)
│   └── Task-branded notification content
├── Analytics
│   ├── Daily view (hourly breakdown)
│   ├── Weekly view (day comparison)
│   ├── Monthly view (streaks, trends)
│   └── Yearly view (macro patterns)
└── Settings & Personalisation
    ├── Theme (light / dark / custom accent)
    ├── First day of week
    ├── Notification defaults
    └── Data export / backup
```

### 2.3 Operating Environment
- **Target OS:** Android 5.0+ (API 21+) and iOS 14.0+
- **Framework:** Flutter (latest stable channel)
- **Local Database:** SQLite via Drift ORM
- **State Management:** Riverpod
- **Push Notifications:** `flutter_local_notifications` package
- **Network (optional sync):** REST API / Firebase (future scope)

### 2.4 Design and Implementation Constraints
- The app shall compile from a single Flutter codebase targeting both Android and iOS.
- All core functionality shall operate without an internet connection (offline-first).
- Notifications shall be powered by the device's native notification system (no server push in v1.0).
- The local database must survive app restarts and OS updates without data loss.

---

## 3. User Classes and Characteristics

| User Class | Description | Technical Skill | Primary Use |
|---|---|---|---|
| **Daily Planner** | Plans each day with specific time-blocked tasks | Low–Medium | Home Screen (Stack) |
| **Habit Builder** | Focuses on recurring daily routines | Low | Repeating tasks + streaks |
| **Time Analyst** | Deep interest in time-use data | Medium–High | Analytics dashboard |
| **Power User** | Uses all features extensively | High | All modules |

All user classes share one common trait: they use the app on a personal, individual basis (no multi-user collaboration in v1.0).

---

## 4. System Features & Functional Requirements

---

### 4.1 Feature: 24-Hour Stack (Home Screen)

**Description:** The primary home screen presents the user's entire day as a vertically scrollable, time-anchored timeline from 00:00 to 23:59. This is the core experience of TaskStack.

#### Functional Requirements

| ID | Requirement |
|---|---|
| FR-001 | The home screen SHALL display a continuous, infinite-scroll vertical timeline representing a full 24-hour period. |
| FR-002 | On app launch, the timeline SHALL auto-scroll to position the current time indicator at the centre of the visible viewport. |
| FR-003 | A clearly styled **current time indicator** (e.g. a horizontal line with live clock label) SHALL move in real time as the clock advances. |
| FR-004 | Each hour of the timeline SHALL be clearly labelled with a time marker (e.g. "09:00 AM"). |
| FR-005 | Tasks scheduled within a time slot SHALL be rendered as task cards on the timeline, vertically aligned to their start time and proportionally sized to their duration. |
| FR-006 | Task cards SHALL visually differentiate between statuses: `Pending` (default), `In Progress` (current time falls within task window), and `Done` (marked by user). |
| FR-007 | Tapping a task card SHALL open the Task Detail view for that task. |
| FR-008 | A persistent Floating Action Button (FAB) SHALL allow the user to create a new task from the home screen. |
| FR-009 | The timeline SHALL support smooth inertial scrolling (fling gestures). |
| FR-010 | Unscheduled tasks (no time frame set) SHALL appear in a collapsible section at the top or bottom of the timeline, labelled "Unscheduled." |
| FR-011 | The date displayed SHALL default to "Today" but the user SHALL be able to swipe left/right to view yesterday's or tomorrow's task stacks. |

---

### 4.2 Feature: Task Creation & Management

**Description:** Users can create, edit, duplicate, and delete tasks. Each task is a rich data object with multiple configurable fields.

#### 4.2.1 Task Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | String (max 80 chars) | Yes | Short, descriptive task name |
| `description` | String (max 500 chars) | No | Detailed notes about the task |
| `purpose` | String (max 200 chars) | No | The *why* — motivation for doing this task |
| `icon` | Icon ID (from library) | No | Custom icon from a curated icon set (default: checkmark) |
| `tags` | List<String> (max 5 tags) | No | User-defined labels for categorisation |
| `startTime` | TimeOfDay | No | Scheduled start time |
| `duration` | Duration (minutes) | No | How long the task is expected to take |
| `recurrence` | Enum / Rule | No | None / Today-Repeat / Daily / Weekly / Custom |
| `notificationOffset` | int (minutes before start) | No | When to fire the notification (-N, 0, or custom) |
| `status` | Enum | Auto | `pending` / `in_progress` / `done` |
| `completedAt` | DateTime | Auto | Set when user marks task as done |
| `color` | Color value | No | Optional task accent colour |

#### 4.2.2 Functional Requirements

| ID | Requirement |
|---|---|
| FR-020 | The app SHALL support creating a task with at minimum a title. All other fields are optional. |
| FR-021 | The task creation screen SHALL present all fields in a clean, sectioned form with inline validation. |
| FR-022 | Title SHALL be validated as non-empty and ≤ 80 characters in real time. |
| FR-023 | Users SHALL be able to select a start time via a native time picker. |
| FR-024 | Users SHALL be able to set a task duration by selecting minutes from a wheel picker or typing a value. |
| FR-025 | Users SHALL be able to add up to 5 custom text tags per task, with autocomplete suggestions based on previously used tags. |
| FR-026 | Users SHALL be able to select a task icon from a library of at least 200 curated icons (categorised by life domain). |
| FR-027 | Users SHALL be able to assign an optional custom accent colour to a task from a predefined palette + custom hex input. |
| FR-028 | Users SHALL be able to set a recurrence rule for a task. Supported recurrence types: `none`, `repeat-today` (repeat this task multiple times today only), `daily`, `weekly`, `custom` (specific days of week). |
| FR-029 | Users SHALL be able to edit any field of an existing task after creation. |
| FR-030 | Users SHALL be able to delete a task. A confirmation dialog SHALL appear before permanent deletion. |
| FR-031 | Deleting a recurring task SHALL ask the user whether to delete: (a) only this instance, (b) this and all future instances, or (c) all instances. |
| FR-032 | Users SHALL be able to duplicate a task (copies all fields, including time frame, as a new independent task). |

---

### 4.3 Feature: Task Repetition Within a Day

**Description:** A user may want to perform the same task multiple times within a single day (e.g., a Pomodoro block, a hydration reminder every 2 hours). The "repeat today" recurrence type facilitates this.

| ID | Requirement |
|---|---|
| FR-040 | A task with `recurrence = repeat-today` SHALL generate multiple instances across the current day based on a user-configured interval (e.g. every 2 hours). |
| FR-041 | The number of daily repetitions SHALL be configurable (default: auto-fill from first instance until end of day, or user-specified count). |
| FR-042 | Each repeat instance SHALL appear as a distinct card on the timeline and carry an independent completion status. |
| FR-043 | Marking one instance as done SHALL NOT affect other instances. |

---

### 4.4 Feature: Notifications

**Description:** TaskStack delivers precise, task-specific local notifications timed to each task.

| ID | Requirement |
|---|---|
| FR-050 | Users SHALL be able to enable or disable notifications per individual task. |
| FR-051 | Users SHALL be able to configure the notification offset per task: `at start time`, `5 minutes before`, `10 minutes before`, `15 minutes before`, `30 minutes before`, or a custom number of minutes. |
| FR-052 | The notification SHALL display the task's title, icon (as notification icon), and first line of description/purpose. |
| FR-053 | Tapping the notification SHALL deep-link the user to the task detail screen in the app. |
| FR-054 | The app SHALL request notification permissions on first launch (Android 13+ / iOS) with a contextual explanation. |
| FR-055 | Scheduled notifications SHALL survive app restarts. The app SHALL reschedule pending notifications on launch. |
| FR-056 | Recurring tasks SHALL automatically schedule the next occurrence's notification upon marking the current instance done. |
| FR-057 | A global notification settings screen SHALL allow the user to set a default notification offset applied to newly created tasks. |

---

### 4.5 Feature: Task Completion

**Description:** Completion is an intentional, explicit act — never automatic.

| ID | Requirement |
|---|---|
| FR-060 | Tasks SHALL never be auto-completed based on elapsed time. |
| FR-061 | Users SHALL mark a task as done via a clearly visible action on the task card (swipe gesture or tap a completion button). |
| FR-062 | Marking a task as done SHALL trigger a visual completion animation (e.g. checkmark sweep, confetti burst). |
| FR-063 | The `completedAt` timestamp SHALL be recorded at the exact moment the user confirms completion. |
| FR-064 | A done task SHALL visually differentiate from pending tasks (e.g. greyed out, strikethrough, check icon shown on timeline). |
| FR-065 | Users SHALL be able to un-mark a completed task (undo completion) within the same day. |

---

### 4.6 Feature: Analytics Dashboard

**Description:** The analytics module transforms task completion data into multi-horizon productivity insights.

#### 4.6.1 Daily Analytics

| ID | Requirement |
|---|---|
| FR-070 | The daily view SHALL display total tasks scheduled, total completed, and completion rate as a percentage. |
| FR-071 | An hourly activity chart (bar chart) SHALL show task density across each hour of the day. |
| FR-072 | A doughnut chart SHALL break down time usage by tag/category. |
| FR-073 | The "Most Productive Hour" SHALL be surfaced as a highlight metric. |
| FR-074 | Users SHALL be able to navigate between days using date navigation arrows or a calendar picker. |

#### 4.6.2 Weekly Analytics

| ID | Requirement |
|---|---|
| FR-080 | The weekly view SHALL display a day-by-day bar chart of tasks completed per day. |
| FR-081 | A productivity score (0–100) based on completion rate + task duration SHALL be computed per day. |
| FR-082 | The best day and worst day of the week SHALL be highlighted. |
| FR-083 | A stacked bar chart SHALL show time distribution by tag across days of the week. |

#### 4.6.3 Monthly Analytics

| ID | Requirement |
|---|---|
| FR-090 | The monthly view SHALL display a heat-map calendar where each day's cell colour intensity represents productivity score. |
| FR-091 | Habit streaks (consecutive days completing a recurring task) SHALL be displayed per tag or per recurring task group. |
| FR-092 | A line chart SHALL show the trend of daily completion rate across the month. |
| FR-093 | Total time logged per tag category for the month SHALL be displayed. |

#### 4.6.4 Yearly Analytics

| ID | Requirement |
|---|---|
| FR-100 | The yearly view SHALL display a GitHub-style contribution heatmap of productivity across all 365 days. |
| FR-101 | Monthly productivity averages SHALL be compared in a bar chart. |
| FR-102 | Year-over-year comparison (if data exists from prior years) SHALL be available as a toggle. |
| FR-103 | Top 3 most used tags for the year SHALL be surfaced. |

---

### 4.7 Feature: Settings & Personalisation

| ID | Requirement |
|---|---|
| FR-110 | The app SHALL support **Light**, **Dark**, and **System-default** themes. |
| FR-111 | Users SHALL be able to select a custom accent colour for the app's primary UI elements. |
| FR-112 | Users SHALL be able to configure the first day of the week (Sunday or Monday). |
| FR-113 | Users SHALL be able to configure the default notification offset (applied to new tasks). |
| FR-114 | Users SHALL be able to export all task data as a JSON file to local storage or a share target. |
| FR-115 | Users SHALL be able to import task data from a previously exported JSON file. |
| FR-116 | A "Clear all tasks for today" action SHALL be available with a confirmation dialog. |
| FR-117 | Users SHALL be able to view app version info, open-source licences, and contact/support links. |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement |
|---|---|
| NFR-001 | The 24-hour timeline SHALL scroll at a sustained 60 fps on mid-range devices (≥ 3 GB RAM). |
| NFR-002 | App cold start (from tap to home screen visible) SHALL complete in ≤ 2 seconds on mid-range hardware. |
| NFR-003 | Task creation/save operations SHALL complete in ≤ 200 ms. |
| NFR-004 | Analytics charts SHALL render within ≤ 500 ms of opening the analytics screen. |
| NFR-005 | Database queries for a single day's tasks SHALL complete in ≤ 50 ms. |

### 5.2 Reliability

| ID | Requirement |
|---|---|
| NFR-010 | Task data SHALL be persisted to the local database immediately upon creation/edit (no data loss on unexpected app termination). |
| NFR-011 | The app SHALL handle database migration gracefully across version upgrades without data loss. |
| NFR-012 | Scheduled notifications SHALL be rescheduled automatically if the device restarts (using appropriate platform boot receivers). |

### 5.3 Usability

| ID | Requirement |
|---|---|
| NFR-020 | First-time users SHALL be guided through onboarding (max 4 screens) explaining core concepts: Stack, Tasks, Mark Done, Analytics. |
| NFR-021 | Any destructive action (delete, clear all) SHALL require explicit user confirmation. |
| NFR-022 | All interactive elements SHALL meet WCAG 2.1 Level AA tap target size guidelines (minimum 44×44 dp). |
| NFR-023 | The app SHALL support Dynamic Text (iOS) and font scaling (Android) up to 150% without layout breakage. |
| NFR-024 | Error states (empty timeline, no analytics data) SHALL display friendly, illustrated empty states — not blank screens. |

### 5.4 Security & Privacy

| ID | Requirement |
|---|---|
| NFR-030 | All task data SHALL be stored exclusively on the user's device (no data sent to external servers in v1.0). |
| NFR-031 | The app SHALL NOT collect any personally identifiable information (PII) in v1.0. |
| NFR-032 | If future cloud sync is added, data SHALL be encrypted in transit (TLS 1.3+) and at rest (AES-256). |

### 5.5 Maintainability

| ID | Requirement |
|---|---|
| NFR-040 | Code SHALL follow Flutter/Dart best practices (linting with `flutter_lints`, meaningful naming, documentation comments). |
| NFR-041 | Business logic SHALL be fully decoupled from UI widgets and testable via unit tests. |
| NFR-042 | The codebase SHALL achieve ≥ 70% unit test coverage on domain and data layers. |
| NFR-043 | The project SHALL use semantic versioning (SemVer) and maintain a CHANGELOG.md. |

### 5.6 Portability

| ID | Requirement |
|---|---|
| NFR-050 | The app SHALL run on Android API ≥ 21 (Android 5.0 Lollipop and above). |
| NFR-051 | The app SHALL run on iOS 14.0 and above. |
| NFR-052 | The app SHALL adapt layout for screen sizes from 4" to 7" phones and support basic tablet layout adaptation. |

---

## 6. External Interface Requirements

### 6.1 User Interfaces

| ID | Requirement |
|---|---|
| IR-001 | All screens SHALL use Material Design 3 (M3) components as the baseline, customised to TaskStack's visual identity. |
| IR-002 | The app SHALL use a bottom navigation bar with tabs: **Stack** (Home), **Tasks** (List View), **Analytics**, **Settings**. |
| IR-003 | The home screen bottom navigation SHALL be overlaid on the timeline without obscuring task content. |
| IR-004 | The task creation/edit screen SHALL use a bottom sheet or full-screen modal pattern. |
| IR-005 | Charts in the analytics screen SHALL use vector-rendered, animated charts (via `fl_chart` or equivalent). |

### 6.2 Hardware Interfaces
- Notification delivery via device notification system (Android NotificationManager / iOS UNUserNotificationCenter)
- Haptic feedback for completion and destructive actions (device vibration motor)
- Touch screen (primary input)

### 6.3 Software Interfaces
| Dependency | Library / SDK | Purpose |
|---|---|---|
| Local Database | `drift` (SQLite ORM) | Persistent task storage |
| State Management | `riverpod` | Reactive state and DI |
| Notifications | `flutter_local_notifications` | Scheduling & delivery |
| Charts | `fl_chart` | Analytics visualisations |
| Icons | `hugeicons` or custom set | Task icon library |
| Date/Time | `intl` | Localisation and formatting |
| UUID | `uuid` | Unique task IDs |
| JSON serialisation | `json_serializable` | Data export/import |

### 6.4 Communications Interfaces
- In v1.0: none (fully offline)
- In v1.5+: HTTPS REST or Firebase Firestore for cloud sync (to be specified in a separate SRS addendum)

---

## 7. Data Requirements

### 7.1 Core Entities

#### Task Entity
```
Task {
  id: UUID (PK)
  title: String
  description: String?
  purpose: String?
  iconId: String?
  color: int? (ARGB)
  tags: List<String>
  startTime: int? (minutes from midnight)
  durationMinutes: int?
  recurrenceType: Enum (none | repeatToday | daily | weekly | custom)
  recurrenceRule: String? (iCal RRULE format for custom)
  repeatInterval: int? (minutes, for repeatToday)
  notificationEnabled: bool
  notificationOffsetMinutes: int
  status: Enum (pending | done)
  completedAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
  parentTaskId: UUID? (FK, for recurring instances)
  date: Date (which calendar day this task belongs to)
}
```

#### Tag Entity
```
Tag {
  id: UUID (PK)
  name: String (unique)
  color: int? (ARGB)
  createdAt: DateTime
}
```

#### Daily Summary Entity (Materialised/Cached)
```
DailySummary {
  date: Date (PK)
  totalScheduled: int
  totalCompleted: int
  totalDurationPlanned: int (minutes)
  totalDurationCompleted: int (minutes)
  productivityScore: double (0.0–100.0)
  tagBreakdown: JSON (tag → minutes)
}
```

### 7.2 Data Volume Estimates (Per User, Per Year)
- Average 10 tasks/day × 365 = ~3,650 task records/year
- Each task record ≈ 1–2 KB → ~7 MB/year of task data
- Total with indexes, summaries, tags: estimated ≤ 20 MB/year (well within mobile storage norms)

### 7.3 Data Retention
- Task data SHALL be retained indefinitely on device unless the user explicitly clears it.
- The "Clear all tasks for today" action SHALL only soft-delete tasks (mark as archived) by default; hard delete requires a separate action.

---

## 8. Constraints & Assumptions

### 8.1 Constraints
- Must be built in Flutter; no native iOS/Android code except platform channel calls for notifications.
- v1.0 must ship without requiring a backend server.
- Notification scheduling is limited by OS-imposed maximums (Android: typically 500 pending alarms; iOS: 64 local notifications). The app must handle this gracefully.

### 8.2 Assumptions
- Users will grant notification permissions when prompted.
- Device clock is the single source of truth for all time-based operations.
- Users understand that `repeat-today` tasks apply only to the current day's stack.
- Task data will not be migrated from other apps in v1.0.
- The target device will have at least 50 MB of free storage.

---

## 9. Appendix — Glossary

| Term | Definition |
|---|---|
| **Stack** | The 24-hour scrollable timeline that is the core home screen of TaskStack |
| **Task Card** | The UI element representing a single task on the timeline |
| **Time Frame** | The combination of a task's start time and duration |
| **Repeat Today** | A recurrence type that duplicates a task multiple times within a single day |
| **Intentional Completion** | The design principle that tasks MUST be manually marked done by the user |
| **Productivity Score** | A computed metric (0–100) based on task completion rate and duration adherence |
| **Streak** | Consecutive days on which a recurring task was completed |
| **In Progress** | The automatic status applied to a task whose time window includes the current moment |
| **Pending** | Default task status — scheduled for the future |
| **Done** | Status manually applied by user to confirm task completion |
| **Tag** | A user-defined label applied to tasks for categorisation and analytics grouping |
| **Offset (Notification)** | The number of minutes before a task's start time at which the notification fires |

---

*End of SRS Document — TaskStack v1.0*
