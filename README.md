<h1 align="center">
  <br/>
  TaskStack
  <br/>
</h1>

<h4 align="center">Your 24-hour life stack. Plan it. Live it. Analyse it.</h4>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.41.2-02569B?logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="https://m3.material.io">
    <img src="https://img.shields.io/badge/Material%20Design-3-6750A4?logo=material-design&logoColor=white" alt="MD3">
  </a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/Status-In%20Development-orange" alt="Status">
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#tech-stack">Tech Stack</a>
</p>

---

## Overview

**TaskStack** is a next-generation daily task management and life analytics app built with Flutter. Instead of flat to-do lists, TaskStack gives you a living, scrollable **24-hour visual timeline** — a real-time view of your entire day that helps you plan with precision, execute with focus, and reflect with data.

> Built strictly on **Material Design 3**, offline-first with SQLite, and powered by multi-horizon analytics.

---

## Features

### 🗓 24-Hour Stack (Home)
- Infinite-scroll timeline from 00:00 → 23:59
- Auto-scrolls to current time on launch with a live time indicator
- Task cards sized proportionally to duration and colour-coded by status
- Swipe right to mark done, long-press for context menu

### ✅ Rich Task Management
- Create tasks with **title, description, purpose, icon, colour, tags, time frame**
- Set repeat-within-today tasks (e.g. every 2 hours)
- Daily, weekly, or fully custom recurrence rules
- Intentional completion — tasks are **never** auto-marked done

### 🔔 Precision Notifications
- Per-task notifications fired at exactly the right time
- Custom offset: at start, 5 / 10 / 15 / 30 minutes before, or custom
- Deep-links from notification directly into the task

### 📊 Analytics Dashboard
| Horizon | What you see |
|---|---|
| **Daily** | Hourly activity chart, tag donut, most productive hour |
| **Weekly** | Day-by-day bar chart, productivity score, tag distribution |
| **Monthly** | Heat-map calendar, habit streaks, trend line |
| **Yearly** | GitHub-style 365-day heatmap, year-over-year comparison |

### ⚙️ Personalisation
- Light / Dark / System theme
- Custom accent colour
- 12h / 24h time format, configurable week start
- JSON data export & import

---

## Architecture

TaskStack follows **Clean Architecture** with strict layer separation:

```
Presentation  →  Domain  →  Data
(Flutter/Riverpod)  (Pure Dart)  (Drift/SQLite)
```

```
lib/
├── core/               # Shared theme, routing, constants, widgets
├── features/
│   ├── task_stack/     # 24-hour timeline feature
│   ├── analytics/      # Analytics dashboard
│   ├── notifications/  # Notification service & scheduler
│   ├── settings/       # App preferences
│   └── onboarding/     # First-launch flow
└── database/           # Drift ORM schema, tables, DAOs
```

---

## Getting Started

### Prerequisites
- Flutter **3.x** or later
- Android Studio / VS Code with Flutter plugin
- Android SDK (API 21+) or Xcode 15+ for iOS

### Clone & Run

```bash
git clone https://github.com/abhayprojects/TaskStack.git
cd TaskStack
flutter pub get
flutter run
```

### Code Generation (Drift + Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Documentation

All project documentation lives in the [`docs/`](./docs) folder:

| Document | Description |
|---|---|
| [Problem Statement](docs/problem_statement.md) | Problem domain, personas, solution overview, success KPIs |
| [SRS](docs/srs.md) | 100+ tagged functional & non-functional requirements |
| [SDD](docs/sdd.md) | Full architecture, DB schema, UI design system, notification engine |
| [UI/UX Map](docs/ui-ux.md) | All screens with wireframes, nav flows, component inventory |
| [Design Principles](docs/design-principles.md) | M3 colour roles, typography scale, spacing, shape, motion tokens |
| [Todo Features](docs/todo-tasks.md) | Planned feature backlog |
| [Ongoing](docs/ongoing-tasks.md) | Currently in-progress work |
| [Finished](docs/finished-tasks.md) | Completed milestones |
| [UI Components](docs/ui/) | Material Design 3 component specs & guidelines |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Design System | Material Design 3 |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Local Database | Drift (SQLite ORM) |
| Notifications | flutter_local_notifications |
| Charts | fl_chart |
| Typography | Google Fonts (Outfit + Inter) |
| Code Generation | build_runner, drift_dev, riverpod_generator |

---

## Roadmap

- [x] Project scaffold & clean architecture setup
- [x] Documentation (Problem Statement, SRS, SDD, UI/UX, Design Principles)
- [ ] 24-hour timeline widget
- [ ] Task creation & management
- [ ] Notifications
- [ ] Analytics dashboard
- [ ] Onboarding flow
- [ ] Settings & personalisation
- [ ] Cloud sync (v1.5)

---

## License

MIT © Abhay
