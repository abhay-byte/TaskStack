# Plan: Fix Task Pre-Start Notifications

**Status:** Ready to merge (notif commits) — product path device-proven; residual optional QA  
**Repo:** `/home/abhay/repos/TaskStack`  
**Branch:** `fix-task-notifications`  
**Date:** 2026-07-25  
**Last updated:** 2026-07-25 (4th plan review)  
**Symptom (original):** Task reminder notifications never fire. Settings “Test Notification” works. UI shows notification enabled + “5 min before”.  
**Device truth:** Notifications working from **first iteration**. AC1 Met — do not re-prove.

---

## 1. Problem summary

| Path | Behavior |
|------|----------|
| Settings **Test Notification** | Immediate create → **fires** (device + committed awesome path) |
| Task schedule (future remind) | **Works since 1st iteration** (device-proven) |
| Remind past, start future | Immediate ~+2s + snackbar |
| Start already past | Skip + snackbar |
| UI / DB | Toggle + offset → entity OK |

---

## 2. Stack

- Flutter app (`com.taskstack.taskstack`)
- `awesome_notifications` (pubspec + settings aligned as of 4th review)
- `timezone` + `flutter_timezone`
- `targetSdk = 36`

---

## 3. End-to-end flow (shipped design)

```
Task form save
  → Create / Update use case (try/catch both)
    → scheduleFor → NotificationScheduleResult
         → canScheduleExact fail-closed
         → calculateScheduleTime (pure; unit-tested incl. cross-midnight)
         → past remind + future start → now+2s, scheduledImmediate
         → start past → skippedPastTask
         → createNotification(preciseAlarm, allowWhileIdle, real second/ms)
         → if !ok → listScheduledNotifications; id absent → failedPluginError
              (list API throw → soft SUCCESS residual)
  → Form snackbar by result → await snackbar closed → pop
Toggle ON → ensureExactAlarmPermission → recheck canScheduleExact before enable
```

---

## 4. Root causes — status (4th review)

| RC | Issue | Status |
|----|--------|--------|
| **RC1** | PreciseAlarms never requested | **Fixed** |
| **RC2** | createNotification bool | **Fixed** — `!ok` → listScheduled verify; absent → `failedPluginError`; list throw → soft residual only |
| **RC3** | Debug kill wipes schedules | **N/A** — release QA (AC5) |
| **RC4** | allowWhileIdle | **Fixed** |
| **RC5** | Silent past skip | **Fixed** |
| **RC6** | Wrong TZ | **Fixed** |
| **RC7** | Boot incomplete | **Open deferred** — BootReceiver comment aligned; implement only if AC5 fails |
| **RC8** | canScheduleExact wrong | **Fixed** |

---

## 5. What is already correct

- Device: scheduled reminders fire (1st iteration+).
- Form/UI → DB notification flags.
- Create/Update → scheduleFor / cancelFor + try/catch both.
- Channel init, exact-alarm manifest perms.
- Cancel id hash stable.
- `NotificationScheduleResult` + form snackbars (`await ctrl.closed`).
- Pure `calculateScheduleTime` + unit tests (future / immediate / skipPast / cross-midnight).
- Toggle: enable only if exact still granted.
- Build: pubspec + lock + settings on awesome (3rd-review 🔴 closed).
- Notif commits isolatable; dirty non-notif tree must stay unstaged.

---

## 6. Phase progress (4th review)

| Phase | Status | Notes |
|-------|--------|--------|
| **A** Device | ✅ | AC1 from 1st iteration |
| **B** Permissions | ✅ | Settings exact-alarm **row** still optional polish (AC3) |
| **C** Scheduler | ✅ | flags, TZ, past/immediate, RC2 verify, pure calc |
| **D** Lifecycle/boot | ⚠️ deferred | comment OK; no headless reschedule |
| **E** UX | ✅ | snackbars + toggle; settings row optional |
| **F** Tests | ✅ | math + cross-midnight; re-run `flutter test` locally if needed |

---

## 7. Minimal diff target (notif PR)

| Owned by notif PR | Notes |
|-------------------|--------|
| `notification_scheduler.dart` | schedule + calc + RC2 verify |
| `notification_service.dart` | PreciseAlarms helpers |
| `task_usecases.dart` / `task_providers.dart` | result return + try/catch |
| `task_form_screen.dart` | toggle + snackbar |
| `settings_screen.dart` | awesome test notif |
| `notification_scheduler_test.dart` | pure math |
| `pubspec.yaml` / lock | awesome |
| BootReceiver | comment only if touched |
| Manifest | exact-alarm (+ justified plugin perms) |

**Exclude:** `app.dart`, DB/dao, stack UI widgets, unrelated tests/gradle.

---

## 8. Acceptance criteria

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Start +10, remind −5 → fires T−5 | **Met** (device, 1st iteration) |
| 2 | listScheduled non-empty after save | **Partial** — used on `!ok` verify; no product UI |
| 3 | Exact granted or guided | **Partial** — form strong; settings row optional |
| 4 | Test notification works | **Met** (committed awesome path) |
| 5 | Background/killed **release** | **Unknown** — only hard leftover QA |
| 6 | Past remind → user told | **Met** (code) |

---

## 9. Out of scope

- iOS critical alerts.
- Further library switches.
- Recurring-window redesign.
- Full OEM battery whitelist.
- Re-proving “never fires” / AC1.
- Phase D implement unless AC5 fails.

---

## 10. Implementation checklist

- [x] Phase A: device future path
- [x] Phase B: PreciseAlarms + form + scheduleFor fail-closed
- [ ] Phase B optional: settings exact-alarm row
- [x] Phase C: flags, TZ, past/immediate, enum, pure calc, RC2 list verify
- [x] Phase E: snackbars + toggle harden + await closed
- [x] Phase F: math + cross-midnight unit tests
- [ ] Phase D: deferred
- [ ] Release QA AC5
- [x] Build hygiene: pubspec + settings awesome
- [ ] PR: stage **only** notif commits / files

---

## 11. Review blockers — history

### 1st review — closed
`final`/`var`, `second:0`, AC6 UX, scheduleFor exact check.

### 2nd review — closed (later)
Toggle harden, Phase F real tests, snackbar delay, RC2 capture.

### 3rd review open → **4th closed**

| # | 3rd issue | 4th outcome |
|---|-----------|-------------|
| 1 | 🔴 pubspec/settings FLN mismatch | **Closed** — awesome aligned |
| 2 | 🟠 RC2 soft-success | **Closed** — listScheduled verify fail-closed when id absent |
| 3 | 🟡 Update try/catch | **Closed** |
| 4 | 🟡 snackbar/pop | **Closed** — `await ctrl.closed` |
| 5 | 🟡 cross-midnight | **Closed** — unit test |
| 6 | 🟡 BootReceiver comment | **Closed**; Phase D still deferred |
| 7 | Scope creep | **OK** if not staged; dirty tree remains |

### 4th review residual (non-blocking)

| # | Severity | Issue |
|---|----------|--------|
| 1 | 🟡 | listScheduled **catch** still soft-SUCCESS (false-neg avoid) |
| 2 | 🟡 | AC5 release kill/background unproven |
| 3 | 💡 | README / sdd / srs still mention `flutter_local_notifications` |
| 4 | 💡 | repeatToday instance loop still no try/catch (parent covered) |
| 5 | 🟢 | Non-notif dirty working tree — never `git add -A` |

**Verdict (4th review):** **APPROVE**

---

## 12. Scope creep

**Notif-owned:** scheduler, service, usecases/providers (result), form, settings test notif, pubspec/lock, notif tests, exact-alarm manifest / BootReceiver comment.

**Keep out:** app.dart, animated_graphic, app_database, task_dao, repositories (if non-result), day_todo_sheet, task_detail/stack screens, task_card, time_indicator, unrelated tests/gradle.

---

## 13. Past-remind product rule

| Condition | Behavior |
|-----------|----------|
| remind past, start future | ~now+2s; `scheduledImmediate`; snackbar |
| start past | `skippedPastTask`; snackbar |
| no exact permission | `failedNoPermission`; snackbar |
| create `!ok` + id not listed | `failedPluginError`; snackbar |
| create `!ok` + list API throws | soft SUCCESS (residual) |

---

## 14. Manual QA

- [x] Future task fires (device, 1st iteration+)
- [x] Test notification path (awesome committed)
- [ ] Optional: start in 3 min, offset 5 → soon + snackbar
- [ ] Optional: start past → snackbar only
- [ ] Optional: deny exact → guided
- [ ] **Release** background/killed (AC5) — optional merge confidence
- [ ] Local: `flutter test test/domain/notification_scheduler_test.dart`

---

## 15. Next actions (post-APPROVE)

1. Open PR with **notif commits only** (e.g. through latest notif fix commit; leave dirty tree unstaged).
2. Optional: release AC5 (kill + background fire).
3. Optional: docs FLN → awesome (README/sdd/srs).
4. Optional: settings “exact alarms” row (AC3 polish).
5. Re-run notif unit tests locally if CI not green yet.
6. Do **not** re-prove AC1.
7. No Phase D unless AC5 fails.

---

## 16. Review log

| When | Verdict | Notes |
|------|---------|--------|
| 2026-07-25 1st | CHANGES_REQUESTED | compile, second:0, AC6, exact fail-closed |
| 2026-07-25 2nd | CHANGES_REQUESTED | RC2 soft; Phase F stub; scope |
| 2026-07-25 3rd | CHANGES_REQUESTED | AC1 device-proven; build hygiene + RC2 verify open |
| 2026-07-25 4th | **APPROVE** | 3rd blockers closed in later commit; residual AC5/docs/soft-list-catch only |

**Merge gate:** notif-only PR. Optional AC5 release smoke. Product schedule path already proven on device.
