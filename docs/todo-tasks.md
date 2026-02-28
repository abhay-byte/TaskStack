# TaskStack — Todo Features

> Features planned for implementation, not yet started.

---

## 🏠 Core — 24-Hour Stack (Home Screen)

- [ ] Infinite-scroll vertical 24-hour timeline widget
- [ ] Auto-scroll to current time on app launch
- [ ] Real-time current-time indicator (live updating every 30s)
- [ ] Hour slot markers with time labels (12h/24h toggle)
- [ ] Task card rendering on timeline (positioned by start time + proportional height)
- [ ] Task card visual states: `pending`, `in_progress`, `done`
- [ ] Unscheduled tasks collapsible section
- [ ] Date navigation (swipe left/right to change day)
- [ ] "Jump to Today" button in date nav bar
- [ ] Floating Action Button (FAB) for quick task creation
- [ ] Smooth inertial scrolling with fling gesture support
- [ ] Task card long-press context menu (Edit / Delete / Duplicate)
- [ ] Swipe-right on task card → mark as done
- [ ] Task card tap → navigate to Task Detail screen
- [ ] Empty state illustration when no tasks are scheduled

---

## ✅ Task Management

- [ ] Task creation form (full screen / bottom sheet modal)
  - [ ] Title field (required, max 80 chars, real-time validation)
  - [ ] Description field (optional, max 500 chars)
  - [ ] Purpose field ("the why", optional, max 200 chars)
  - [ ] Icon picker (library of 200+ categorised icons)
  - [ ] Accent colour picker (palette + custom hex)
  - [ ] Tag input (max 5 tags, autocomplete from history)
  - [ ] Start time picker (native time picker)
  - [ ] Duration picker (wheel / text input, in minutes)
  - [ ] Recurrence type selector (None / Repeat Today / Daily / Weekly / Custom)
  - [ ] Repeat interval picker (for Repeat Today)
  - [ ] Custom recurrence rule builder (day-of-week selector)
  - [ ] Notification toggle per task
  - [ ] Notification offset selector (at start / 5 / 10 / 15 / 30 min before / custom)
- [ ] Task edit screen (pre-filled form)
- [ ] Task detail screen (full read view with edit + delete + complete actions)
- [ ] Task deletion with confirmation dialog
- [ ] Delete recurring task: single / this & future / all instances dialog
- [ ] Task duplication (copy all fields as new independent task)
- [ ] Intentional completion marking with animation
- [ ] Undo completion within same day

---

## 🔁 Repeat Today Logic

- [ ] Generate intra-day repeat instances based on interval
- [ ] Auto-fill repeat instances until end of day (or user-specified count)
- [ ] Independent completion status per repeat instance
- [ ] Notification scheduling for each repeat instance

---

## 🔔 Notifications

- [ ] `flutter_local_notifications` plugin integration
- [ ] Request notification permissions on first launch (with explanation)
- [ ] Schedule per-task notifications at computed time offset
- [ ] Task-branded notification: icon, title, purpose/description body
- [ ] Deep-link from notification → Task Detail screen
- [ ] Persist scheduled notifications across app restarts
- [ ] Android boot receiver to reschedule on device restart
- [ ] Cancel notification on task deletion
- [ ] Reschedule notification when task time is edited
- [ ] Auto-schedule next-occurrence notification on recurring task completion

---

## 📊 Analytics

### Daily
- [ ] Total scheduled / completed / completion rate card
- [ ] Hourly activity bar chart
- [ ] Tag/category doughnut chart for time distribution
- [ ] "Most Productive Hour" highlight metric
- [ ] Day navigation with date picker

### Weekly
- [ ] Day-by-day tasks-completed bar chart
- [ ] Productivity score (0–100) per day
- [ ] Best day / worst day highlights
- [ ] Stacked bar chart: tag time distribution by day

### Monthly
- [ ] Heat-map calendar (intensity = productivity score)
- [ ] Habit streak tracker per recurring task / tag
- [ ] Monthly completion rate trend line chart
- [ ] Total time logged per tag

### Yearly
- [ ] GitHub-style 365-day contribution heatmap
- [ ] Monthly productivity average bar chart
- [ ] Year-over-year comparison toggle
- [ ] Top 3 most used tags of the year

---

## ⚙️ Settings & Personalisation

- [ ] Light / Dark / System-default theme toggle
- [ ] Custom accent colour picker for app primary colour
- [ ] First day of week setting (Sunday / Monday)
- [ ] Default notification offset preference
- [ ] 12h / 24h time format toggle
- [ ] Export all task data as JSON
- [ ] Import task data from JSON
- [ ] "Clear all tasks for today" with confirmation
- [ ] App info: version, changelog, licences, support link

---

## 🌟 Onboarding

- [ ] First-launch onboarding flow (4 screens)
  - [ ] Screen 1: Welcome + app concept (The 24-hour Stack)
  - [ ] Screen 2: Creating your first task
  - [ ] Screen 3: Mark as Done — intentional completion concept
  - [ ] Screen 4: Analytics overview
- [ ] Skip onboarding option
- [ ] Notification permission request screen (after onboarding)

---

## 🏗️ Infrastructure & Architecture

- [ ] Clean Architecture folder structure scaffold
- [ ] Drift database setup (AppDatabase, tables, DAOs)
- [ ] Riverpod ProviderScope setup in main.dart
- [ ] GoRouter navigation configuration
- [ ] Flavour configuration (dev / staging / production)
- [ ] Linting setup (`flutter_lints`)
- [ ] Unit test scaffold (domain + data layer)
- [ ] Widget test scaffold
- [ ] Integration test scaffold
- [ ] GitHub Actions CI/CD pipeline

---

*Last updated: 2026-02-28*
