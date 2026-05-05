# Todo Tasks

## ✅ All Phases Complete

All tracked phases and issues are now resolved:
- ✅ Phase 10: Task Cloud Sync
- ✅ Phase 11: Guest Mode
- ✅ Phase 12: Bug Fixes + Delete Account + Day Todo + Group Delete
- ✅ Phase 13: Rolling 2-Week Window + FPS Fix + Comprehensive Tests

## ✅ Phase 13: Goals Page Rehaul — COMPLETE
- [x] Update Goal entity — add `iconId`, `graphicImage`, `colorArgb`, `isGoal`
- [x] Update GoalsTable schema + migration to v6
- [x] Update GoalDao — `watchTasksForGoal`, `getTasksForGoalInRange`, `getCommittedMinutesForGoal`
- [x] Update GoalRepository — map new fields, committed-time queries
- [x] Rehaul GoalsListScreen — M3 cards, progress bar, 30-day timeline, "Goals" title
- [x] Rehaul GoalFormScreen — icon picker, colour picker, `isGoal` toggle, "New Goal" title
- [x] Update Firebase sync — push/pull `iconId`, `graphicImage`, `colorArgb`, `isGoal`
- [x] Write tests — DAO (5), repository (6), widgets (10) = 21 new tests, all passing

## ✅ Phase 14: Rolling 2-Week Window + FPS Fix — COMPLETE
- [x] Replace 365-row upfront generation with rolling 2-week window
- [x] Add `MaintainRecurringWindowUseCase`
- [x] Add DAO methods: `getRecurringParents`, `getInstanceDatesInRange`, `deleteOldPendingInstances`
- [x] Simplify `TaskCardWidget` — remove scroll-tracking, make StatelessWidget
- [x] Write 5 new test files (1788 lines) + update 4 existing test files
- [x] Update docs: SDD, ER diagram, progress tracking, changelog

See `finished-tasks.md` and `docs/changelog.md` for complete details.

---

## 🔮 Future Enhancements (Post v1.0)
- Signed release APK (keystore ready)
- Flavour `productFlavours` in `build.gradle.kts`
- Headless background isolate for persistent notifications
- Deeper analytics: streak tracking, category breakdowns
- Full-text task search
- Home screen widget for today's top 3 tasks
