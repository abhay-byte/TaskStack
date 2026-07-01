# Stack Page Review — Infinite Scroll Timeline

Reviewed files: `task_stack_screen.dart`, `task_card_widget.dart`, `time_indicator_widget.dart`, `task_providers.dart`, `task_usecases.dart`, `task_dao.dart`

---

## Critical

### C1. Center-index approach creates ~57Mpx scroll extent — scroll physics degrade

`_kCenterIndex = 10000` with `itemExtent: 2880px` makes `ListView.builder` manage 20,001 virtual items spanning ~57.6 million pixels. Flutter's `ScrollPhysics` computes deceleration and fling distance from the total scroll extent — with 57Mpx the velocity calculations break down and the scroll feels sluggish or unresponsive on fast flings. Scroll precision also degrades because a single-pixel offset error at the controller level maps to a much larger visual offset in this coordinate space.

**Fix**: Replace the center-index approach with a sliding-window model:

- Start with ~5 items centered on today
- When the user scrolls near the first or last item, `prepend`/`append` a page and adjust `_scrollController.offset` by 2880px to keep the visual position stable (same technique as `ListWheelScrollView` internally). Since the list never exceeds ~50 items, total scroll extent stays under 150,000px and physics work correctly.

### C2. Goal map rebuilt on every scroll — cascading rebuilds through entire visible tree

`_InfiniteDayList.build()` creates a **new** `Map<String, String>` on every rebuild (every scroll frame). This map is passed to every visible `_DayViewBlock` → `_PositionedTaskCard`. Each card gets a new object reference, so even if goal data hasn't changed, every card evaluates its layout. With 20+ visible task cards, a single scroll pixel triggers the full widget tree to reconsider.

```dart
// _InfiniteDayList.build() — runs on every scroll
final goalById = <String, String>{};  // new allocation every time
goalsAsync.whenData((goals) {
  for (final g in goals) {
    goalById[g.id] = g.title;  // rebuilds even when goals haven't changed
  }
});
```

**Fix**: Either (a) wrap the map construction in `ref.watch(goalsProvider).whenData(...)` with a `select` that only fires when goals change, or (b) memoize the map with a separate `Provider` that transforms goals into the lookup map once, then watch that provider.

---

## High

### H1. Hour grid uses 72+ widgets for background lines — should be `CustomPainter`

`_HourGrid` → `_HourRow` produces 24 `_HourRow` widgets per day block. Each row contains a `SizedBox` → `Row` → `SizedBox`+padding → `Text` + `Expanded` → `DecoratedBox` with `BoxDecoration` (which creates a `RenderDecoratedBox` + `Border` render object). With 3 visible days that's ~72 widget subtrees and ~360 render objects for **static background grid lines** — lines that never change.

**Fix**: Replace the `_HourGrid` widget tree with a `CustomPainter` that draws the hour labels and horizontal lines directly on a canvas. `shouldRepaint` returns `false` (the grid doesn't change), so it paints once and never repaints. Reduces widget count by ~70 per visible day.

### H2. `_PositionedTaskCard` is `ConsumerWidget` but never watches a provider

`_PositionedTaskCard` extends `ConsumerWidget` but only uses `ref.read(...)` inside callback closures (`onDone`, `onDelete`). It inherits `ref` from `_DayViewBlock` (also `ConsumerWidget`). Every `ConsumerWidget` that enters the build tree consumes resources for the `Consumer` scope — but here 20+ cards per viewport are all doing it unnecessarily.

**Fix**: Change to `StatelessWidget` and pass `WidgetRef ref` as a constructor parameter from the parent. The parent already has the ref.

### H3. No `addAutomaticKeepAlives: false` + no `cacheExtent` tuning

`ListView.builder` defaults `addAutomaticKeepAlives` to `true`, which retains child elements in the element tree. Since each child is 2880px tall, even keeping 5 extra children off-screen means ~14,400px of retained widgets — each containing the full hour grid, task cards, etc. The default `cacheExtent` (~250px) also means only fractions of an extra day are cached, so scrolling back by one day triggers a full rebuild of that day block.

**Fix**: Set `addAutomaticKeepAlives: false` and `cacheExtent: _kDayBlockHeight * 2` so the 2 adjacent days are always pre-built but nothing more. Combine with the sliding-window fix (C1) to keep total count bounded.

---

## Medium

### M1. `sortedTasksForDateProvider` allocates on every read

```dart
final sortedTasksForDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final async = ref.watch(tasksForDateProvider(date));
  final tasks = async.value ?? [];
  return [...tasks]..sort(...);  // new list + sort on every read
});
```

Every time a `_DayViewBlock` rebuilds (on scroll), it re-watches `sortedTasksForDateProvider`, which re-reads `tasksForDateProvider`, creates a spread copy, and sorts. Even when the stream hasn't emitted new data.

**Fix**: Since `Provider.family` caches per date, the sort only re-runs when `tasksForDateProvider(date)` emits a new value — so this is already partially cached. But the spread `[...tasks]` still allocates even when the list reference is the same. Consider checking reference equality before allocating — or switching to `StreamProvider.family` with a sorted stream from the DAO.

### M2. Redundant provider chain — `sortedTasksProvider` and friends

`sortedTasksForDateProvider` → `sortedTasksProvider` → `scheduledTasksProvider` → `unscheduledTasksForDateProvider` creates a chain of 4+ providers for what is essentially one filtered/sorted list. Each provider in the chain adds overhead for Riverpod's dependency tracking.

**Fix**: Merge the chain into the provider that actually needs it (`_DayViewBlock` already splits scheduled from unscheduled locally). Remove unused providers (`sortedTasksProvider`, `scheduledTasksProvider`) or defer the split to the widget level.

### M3. `_scrollToNow` reads `MediaQuery` in a scroll-computation context

```dart
final timeOffset = (now.hour * 60 + now.minute) * _kMinuteHeight -
    MediaQuery.of(context).size.height * _kDayFocusAnchor;
```

`MediaQuery.of(context)` here creates a hidden dependency on the build context's inherited widget. If `_scrollToNow` is called outside a valid build context (e.g., on first frame before layout is complete), the `MediaQuery` may return stale or zero values.

**Fix**: Store `MediaQuery.of(context).size.height` as a field after the first valid build frame, or use `_scrollController.position.viewportDimension` which is the actual viewport height.

### M4. Recurring window maintenance fires on every 30-min tick but checks `now.minute == 0`

```dart
_recurringTimer = Timer.periodic(const Duration(minutes: 30), (_) {
  final now = DateTime.now();
  if (now.minute == 0) {
    ref.read(maintainRecurringWindowUseCaseProvider).execute();
  }
});
```

The timer fires every 30 minutes but only acts when the minute is 0. This means 29 out of 30 ticks are wasted. On app start the timing of the first tick depends on when the timer was created, so the execution may drift by up to 30 minutes.

**Fix**: Use `Timer` that computes the delay to the next `:00` minute (e.g., `Duration(seconds: (60 - DateTime.now().second) % 60)`) and then repeats on the hour. Or simply call it once on init and let the next init (app restart) handle the next maintenance.

---

## Low

### L1. `_UnscheduledSection` uses `StatefulWidget` for expand/collapse — fine but could be lifted

The expand state is local to the widget, which means scrolling away and back resets the expand state. If the user wants to keep the unscheduled section open while scrolling, this doesn't work.

### L2. `_DayDividerLabel` shows the *next* day at the bottom of each day block

```dart
final next = pageDate.add(const Duration(days: 1));
```

The label at `bottom: 40` of a 2880px block shows "Wed, Jul 2" when the block is for July 1. This is a design choice (it shows what's coming next), but it's worth noting in case this is unintended — the comment in the code implies it's by design.

### L3. `TimeIndicatorWidget` uses `RepaintBoundary` + ticker — good optimization

This one is actually well-optimized. The `Ticker` only calls `setState` when the minute changes (guarded by `_lastMinute`), and `RepaintBoundary` isolates the repaint. Minor: could use `CustomPainter` for the line+dot instead of `Row` → `Container` + `Container`, but the current approach is fine for a once-per-minute repaint.

---

## Summary

| Severity | Count | Key pattern |
|----------|-------|-------------|
| **Critical** | 2 | Center-index scroll physics, goal map rebuild cascade |
| **High** | 3 | Hour grid as widgets, unnecessary ConsumerWidget, cache tuning |
| **Medium** | 4 | List allocations, provider chain, MediaQuery in scroll, timer waste |
| **Low** | 3 | Expand state reset, divider label intent, minor widget optimization |

**First priority**: Replace the center-index infinite scroll with a sliding-window model (C1) — this fixes the core scrolling feel and lets you bound the list size, which simplifies everything else.

**Second priority**: Memoize the goal title map (C2) and convert the hour grid to `CustomPainter` (H1) — these two changes eliminate the bulk of unnecessary rebuilds during scroll.
