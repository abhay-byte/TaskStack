# TaskStack — UI/UX Page Map & Navigation

**Document Version:** 1.0  
**Date:** 2026-02-28  
**Platform:** Flutter (Android & iOS)

---

## Navigation Architecture

TaskStack uses a **bottom navigation bar** (Material 3 `NavigationBar`) as the primary nav surface for 3 top-level destinations, with modal routes for task creation, detail, and settings.

```
Root
├── [Bottom Nav] Stack (Home)       → /
├── [Bottom Nav] Analytics          → /analytics
├── [Bottom Nav] Settings           → /settings
│
├── [Modal] Task Create             → /task/new
├── [Modal] Task Edit               → /task/:id/edit
├── [Screen] Task Detail            → /task/:id
│
└── [Full Screen] Onboarding        → /onboarding   (first launch only)
```

---

## Navigation Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          APP LAUNCH                                     │
│                              │                                          │
│              ┌───────────────┴─────────────────┐                       │
│              ▼                                  ▼                       │
│     [First Launch?]                    [Returning User]                 │
│              │                                  │                       │
│              ▼                                  ▼                       │
│    ┌──────────────────┐              ┌──────────────────────┐           │
│    │  Onboarding Flow │              │    Stack Screen (/)  │           │
│    │  (4 pages)       │              │    24-Hour Timeline  │           │
│    └─────────┬────────┘              └──────────┬───────────┘           │
│              │ Done                             │                       │
│              ▼                                  │                       │
│    ┌──────────────────┐                         │                       │
│    │  Notification    │                         │                       │
│    │  Permission Req  │                         │                       │
│    └─────────┬────────┘                         │                       │
│              │                                  │                       │
│              └────────────────┬─────────────────┘                       │
│                               ▼                                         │
│                 ┌─────────────────────────┐                             │
│                 │   MAIN APP SHELL        │                             │
│                 │   (BottomNavBar)        │                             │
│                 └──────┬────────┬─────────┘                             │
│                        │        │           │                           │
│              ┌─────────┘        │           └──────────┐                │
│              ▼                  ▼                       ▼                │
│   ┌────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│   │  Stack Screen  │  │ Analytics Screen│  │ Settings Screen │         │
│   │    (Home)      │  │   (Tabs)        │  │                 │         │
│   └───────┬────────┘  └────────┬────────┘  └─────────────────┘         │
│           │                    │                                        │
│     ┌─────┴───────┐     ┌──────┴──────┐                                │
│     │             │     │             │                                  │
│     ▼             ▼     ▼             ▼                                  │
│  [TAP Card]   [FAB/+]  Daily       Weekly                               │
│     │             │   Weekly      Monthly                               │
│     ▼             ▼   Monthly     Yearly                                │
│  Task Detail  Task Create                                               │
│  Screen       Screen (Modal)                                            │
│     │                                                                   │
│     ▼                                                                   │
│  Task Edit                                                              │
│  Screen (Modal)                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Screen Specifications

---

### 1. Onboarding Flow — `/onboarding`

**Type:** Full-screen page view (swipeable, 4 pages)  
**Trigger:** First app launch only  
**Transition:** Horizontal slide page transition

#### Page 1 — Welcome
```
┌─────────────────────────────────┐
│                                 │
│         [Lottie Animation]      │
│         (Stack/Clock icon)      │
│                                 │
│    Welcome to TaskStack         │  ← displayLarge
│    Your 24-hour life stack.     │  ← bodyLarge, textSecondary
│                                 │
│         ○ ● ○ ○   (page dots)   │
│                                 │
│    [Skip]          [Next →]     │
└─────────────────────────────────┘
```
- **Components:** `PageView`, `Lottie`, `FilledButton`, `TextButton`

#### Page 2 — The Stack
```
┌─────────────────────────────────┐
│                                 │
│  [Illustration: Timeline]       │
│                                 │
│  Your Day, Visualised           │
│  Every task lives on your       │
│  24-hour timeline.              │
│                                 │
│        ○ ○ ● ○                  │
│    [Skip]          [Next →]     │
└─────────────────────────────────┘
```

#### Page 3 — Add & Customise Tasks
```
┌─────────────────────────────────┐
│  [Illustration: Task creation]  │
│                                 │
│  Build Your Stack               │
│  Add tasks with time, tags,     │
│  icons and purpose.             │
│       ○ ○ ○ ●                   │
│    [Skip]          [Next →]     │
└─────────────────────────────────┘
```

#### Page 4 — Mark Done + Analytics
```
┌─────────────────────────────────┐
│  [Illustration: Chart + Check]  │
│                                 │
│  Own Your Time                  │
│  Mark tasks done intentionally. │
│  See how your time is spent.    │
│        ● ● ● ●                  │
│               [Get Started →]   │
└─────────────────────────────────┘
```

---

### 2. Stack Screen (Home) — `/`

**Type:** Shell route (persistent bottom nav)  
**Primary widget:** `CustomScrollView` / `SliverStack`

```
┌─────────────────────────────────┐
│  ≡   TaskStack   [Today] [⚙]   │  ← TopAppBar (small, M3)
├─────────────────────────────────┤
│  ← Feb 27    📅 TODAY    Feb 29 →│  ← Date navigation bar
├─────────────────────────────────┤
│                                 │
│  06:00 ─────────────────────── │  ← HourMarker
│                                 │
│  07:00 ──────────────────────── │
│  ┌─── Morning Run  🏃 ─────────┐│  ← Task Card (in_progress)
│  │ 07:00 – 07:45  #health      ││    Accent border + pulse anim
│  └─────────────────────────────┘│
│                                 │
│  08:00 ──────────────────────── │
│  ┌─── Review Emails  📧 ───────┐│  ← Task Card (pending)
│  │ 08:30 – 09:00  #work        ││
│  └─────────────────────────────┘│
│                                 │
│  09:00  ────────────────────── │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  NOW │  ← Current time indicator
│                                 │
│  ┌─── Strategy Meeting  💼 ────┐│  ← Task Card (pending)
│  │ 09:15 – 10:30  #work        ││
│  └─────────────────────────────┘│
│                                 │
│  [▾ Unscheduled (2)]            │  ← Collapsible section
│                                 │
├──────────┬──────────┬───────────┤
│  🗓 Stack │ 📊 Stats │ ⚙ Settings│  ← Bottom NavigationBar
└──────────┴──────────┴───────────┘
                    [+]              ← FAB (bottom right)
```

**Interactions:**
- Swipe left/right on date bar → navigate to prev/next day
- Tap `[Today]` → jump date to current day + scroll to now
- Tap task card → `TaskDetailScreen`
- Long-press task card → contextual menu (Edit / Duplicate / Delete)
- Swipe task card right → mark done (with confirmation haptic)
- Tap `[+]` FAB → `TaskFormScreen` (create new)
- Tap `[▾ Unscheduled]` → expand unscheduled tasks section

---

### 3. Task Detail Screen — `/task/:id`

**Type:** Standard route pushed on top of shell  
**Transition:** Forward/backward (Predictive Back on Android 14+)

```
┌─────────────────────────────────┐
│  ←   Task Detail    [✏ Edit]   │  ← TopAppBar with back + edit
├─────────────────────────────────┤
│                                 │
│  🏃  Morning Run               │  ← Icon + Title (headlineMedium)
│  ──────────────────────────     │
│  07:00 – 07:45  (45 min)       │  ← Time frame chip row
│  📅 Today  🔁 Daily            │  ← Date + recurrence chips
│                                 │
│  Tags                           │  ← Section label
│  [#health] [#fitness]           │  ← Tag chips
│                                 │
│  Description                    │
│  Morning jog around the park    │
│                                 │
│  Purpose                        │
│  Stay energized for the day     │
│                                 │
│  Notification                   │
│  🔔 5 minutes before           │
│                                 │
│  Status                         │
│  ⏳ Pending                    │
│                                 │
├─────────────────────────────────┤
│   [🗑 Delete]    [✅ Mark Done]  │  ← Bottom action bar
└─────────────────────────────────┘
```

**Interactions:**
- `[✏ Edit]` → `TaskFormScreen` with task data pre-filled
- `[✅ Mark Done]` → triggers completion animation → status = done → navigate back
- `[🗑 Delete]` → confirmation dialog → delete → navigate back

---

### 4. Task Create / Edit Screen — `/task/new` & `/task/:id/edit`

**Type:** Modal full-screen route (slides up from bottom)  
**Bottom sheet on create, full screen on edit**

```
┌─────────────────────────────────┐
│  ✕  New Task             [Save] │  ← TopAppBar: close + save
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ Title *                 │   │  ← TextField (outlined, M3)
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Description             │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Purpose (the why?)      │   │
│  └─────────────────────────┘   │
│  ─────── Scheduling ────────   │  ← Section divider
│                                 │
│  Start Time        07:00 AM  ›  │  ← ListTile → time picker
│  Duration          45 min    ›  │  ← ListTile → duration picker
│                                 │
│  Repeat            None      ›  │  ← ListTile → recurrence picker
│                                 │
│  ─────── Details ───────────   │
│                                 │
│  Icon          [🏃]          ›  │  ← Icon picker
│  Colour        [■ Indigo]    ›  │  ← Colour picker
│  Tags          [#health] [+] ›  │  ← Tag input
│                                 │
│  ─────── Notification ──────   │
│                                 │
│  Notify me    [5 min before] ›  │  ← Dropdown/sheet picker
│               [Toggle ON/OFF]   │
│                                 │
└─────────────────────────────────┘
```

**Interactions:**
- All field taps → inline pickers (time picker, duration wheel, icon grid, colour grid, tag chips)
- `[Save]` → validation → save task → navigate back
- `[✕]` → discard dialog if form is dirty → navigate back
- Keyboard aware: form scrolls above keyboard (use `SingleChildScrollView`)

---

### 5. Analytics Screen — `/analytics`

**Type:** Shell route (persistent bottom nav)  
**Primary widget:** `DefaultTabController` with 4 tabs

```
┌─────────────────────────────────┐
│       Analytics                 │  ← TopAppBar (centre title)
├──────┬──────┬──────┬────────────┤
│ Day  │ Week │Month │  Year      │  ← TabBar (M3 style)
├──────┴──────┴──────┴────────────┤
│                                 │
│  Today · Feb 28, 2026   ← →     │  ← Date navigation
│  ─────────────────────────────  │
│                                 │
│  ┌──────┐  ┌──────┐  ┌───────┐ │
│  │  8   │  │  5   │  │ 62%   │ │  ← Summary stat cards
│  │Total │  │ Done │  │ Score │ │
│  └──────┘  └──────┘  └───────┘ │
│                                 │
│  Time by Hour                   │  ← Section label
│  [=====Bar Chart============]   │
│                                 │
│  Time by Tag                    │
│  [======Donut Chart=========]  │
│                                 │
│  Most Productive Hour           │
│  ⚡ 09:00 – 10:00              │
│                                 │
├──────────┬──────────┬───────────┤
│  🗓 Stack │ 📊 Stats │ ⚙ Settings│
└──────────┴──────────┴───────────┘
```

**Weekly tab layout:**
```
│  Feb 22 – Feb 28, 2026  ← →    │
│  [==Day Comparison Bar Chart==] │
│  Best Day: Wednesday ⭐         │
│  [==Stacked Tag Bar Chart=====] │
```

**Monthly tab layout:**
```
│  February 2026       ← →       │
│  [==Heat Map Calendar=========] │
│  Streak: 🔥 7 days (Morning Run)│
│  [==Line Chart (trend)========] │
```

**Yearly tab layout:**
```
│  2026                ← →       │
│  [==GitHub Heatmap (52 weeks)==] │
│  [==Monthly Avg Bar Chart=====] │
│  Top Tags: #work #health #learn │
```

---

### 6. Settings Screen — `/settings`

**Type:** Shell route  
**Primary widget:** `ListView` of `ListTile` sections

```
┌─────────────────────────────────┐
│       Settings                  │
├─────────────────────────────────┤
│                                 │
│  ── Appearance ───────────────  │
│  Theme         [Light/Dark/Sys] │  ← SegmentedButton
│  Accent Colour [■ Indigo]    ›  │
│                                 │
│  ── Preferences ──────────────  │
│  Time Format   [12h / 24h]      │  ← SegmentedButton
│  Week Start    [Sun / Mon]      │  ← SegmentedButton
│  Notification  [5 min before] › │
│                                 │
│  ── Data ─────────────────────  │
│  Export Data               ›    │
│  Import Data               ›    │
│  Clear Today's Tasks       ›    │
│                                 │
│  ── About ─────────────────── │
│  Version           1.0.0+1      │
│  Open Source Licences      ›    │
│  Support & Feedback        ›    │
│                                 │
└─────────────────────────────────┘
```

---

## Navigation Rules & Patterns

### Transition Types (GoRouter + M3)

| From → To | Transition |
|---|---|
| Shell tab → Shell tab | None (instant swap) |
| Any → Task Detail | Forward (slide left) |
| Task Detail → Task Edit | Forward (slide left) |
| Any → Task Create | Modal (slide up) |
| Task Edit/Create → back | Modal dismiss (slide down) |
| App launch → Onboarding | Fade |
| Onboarding page → page | Horizontal slide |
| Notification tap → Task Detail | Deep link (pop to root + push) |

### Back Navigation

- All `← back` arrows use `Navigator.pop()` or GoRouter `.pop()`
- Task Create/Edit screens check for dirty state and show **discard confirmation** dialog before popping
- Android predictive back gesture is supported (Flutter 3.22+)

### Deep Linking

| Notification Payload | Deep Link Target |
|---|---|
| `taskId` | `/task/{taskId}` |

Deep links from notifications go to a fully-resolved `TaskDetailScreen`, popping any existing stack to root first.

---

## Component Inventory

| Screen | Key Components |
|---|---|
| Onboarding | `PageView`, `SmoothPageIndicator`, `Lottie`, `FilledButton`, `TextButton` |
| Stack (Home) | `CustomScrollView`, `SliverStack`, `ListView.builder`, `Stack`, `AnimatedPositioned`, `FAB`, `NavigationBar`, `Dismissible` |
| Task Detail | `AppBar`, `Column`, `Chip`, `ElevatedButton`, `FilledButton.tonal` |
| Task Form | `AppBar`, `Form`, `TextField`, `ListTile`, `BottomSheet` pickers, `AnimatedSwitcher` |
| Analytics | `TabBar`, `TabBarView`, `fl_chart` (BarChart, LineChart, PieChart), `CalendarHeatmap` (custom) |
| Settings | `ListView`, `ListTile`, `SegmentedButton`, `Switch`, `Divider` |

---

*Last updated: 2026-02-28*
