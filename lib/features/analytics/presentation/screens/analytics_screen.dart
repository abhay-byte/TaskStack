import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/features/analytics/presentation/providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'Year'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DailyAnalyticsTab(),
          WeeklyAnalyticsTab(),
          MonthlyAnalyticsTab(),
          YearlyAnalyticsTab(),
        ],
      ),
    );
  }
}

// ── Daily Tab ─────────────────────────────────────────────────────────────

class DailyAnalyticsTab extends ConsumerWidget {
  const DailyAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedStackDateProvider);
    final tasksAsync = ref.watch(tasksForDateProvider(date));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final total = tasks.length;
        final done = tasks.where((t) => t.isDone).length;
        final rate = total == 0 ? 0.0 : done / total;

        // Hourly activity: count tasks per hour
        final hourly = List.filled(24, 0);
        for (final t in tasks) {
          if (t.startMinutes != null) {
            hourly[t.startMinutes! ~/ 60]++;
          }
        }
        final mostProductiveHour =
            hourly.indexOf(hourly.reduce((a, b) => a > b ? a : b));

        // Tag distribution
        final tagCounts = <String, int>{};
        for (final t in tasks) {
          for (final tag in t.tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }

        final cs = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Stat cards row
            Row(
              children: [
                _StatCard(
                  label: 'Scheduled',
                  value: '$total',
                  icon: Icons.calendar_today,
                  color: cs.primaryContainer,
                  onColor: cs.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatCard(
                  label: 'Completed',
                  value: '$done',
                  icon: Icons.check_circle_outline,
                  color: cs.secondaryContainer,
                  onColor: cs.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatCard(
                  label: 'Rate',
                  value: '${(rate * 100).toInt()}%',
                  icon: Icons.trending_up,
                  color: cs.tertiaryContainer,
                  onColor: cs.onTertiaryContainer,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Most productive hour
            if (total > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bolt),
                  title: const Text('Most Active Hour'),
                  trailing: Text(
                    mostProductiveHour < 12
                        ? '$mostProductiveHour AM'
                        : '${mostProductiveHour - 12} PM',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Hourly bar chart
            if (total > 0) ...[
              Text('Hourly Activity',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(
                      24,
                      (h) => BarChartGroupData(
                        x: h,
                        barRods: [
                          BarChartRodData(
                            toY: hourly[h].toDouble(),
                            color: cs.primary,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 6,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}h',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Tag donut
            if (tagCounts.isNotEmpty) ...[
              Text('Tag Distribution',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: tagCounts.entries.toList().asMap().entries.map(
                      (e) {
                        final colors = [
                          cs.primary, cs.secondary,
                          cs.tertiary, cs.error,
                          cs.outline,
                        ];
                        return PieChartSectionData(
                          value: e.value.value.toDouble(),
                          title: e.value.key,
                          color: colors[e.key % colors.length],
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 11, color: Colors.white),
                        );
                      },
                    ).toList(),
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],

            if (total == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text('No tasks for this day'),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Weekly Tab ────────────────────────────────────────────────────────────

class WeeklyAnalyticsTab extends ConsumerWidget {
  const WeeklyAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weeklyTasksProvider);
    final cs = Theme.of(context).colorScheme;

    return weekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (weekData) {
        final totals = weekData.map((d) => d.length).toList();
        final dones = weekData.map((d) => d.where((t) => t.isDone).length).toList();
        final labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
        final scores = List.generate(
          7,
          (i) => totals[i] == 0 ? 0.0 : (dones[i] / totals[i]) * 100,
        );
        final bestDay = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Best + worst day
            Card(
              child: ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Best Day'),
                trailing: Text(
                  labels[bestDay],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Tasks Completed per Day',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dones[i].toDouble(),
                          color: cs.primary,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: totals[i].toDouble(),
                            color: cs.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => Text(
                          labels[v.toInt()],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Productivity Score (0–100)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(7, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 28,
                        child: Text(labels[i],
                            style:
                                Theme.of(context).textTheme.labelMedium)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: scores[i] / 100,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${scores[i].toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Monthly Tab ───────────────────────────────────────────────────────────

class MonthlyAnalyticsTab extends ConsumerWidget {
  const MonthlyAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthAsync = ref.watch(monthlyTasksProvider);
    final cs = Theme.of(context).colorScheme;

    return monthAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (monthData) {
        // Heat-map style calendar
        final now = DateTime.now();
        final daysInMonth =
            DateUtils.getDaysInMonth(now.year, now.month);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('This Month', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(daysInMonth, (i) {
                final day = i + 1;
                final dayTasks = monthData[day] ?? [];
                final total = dayTasks.length;
                final done = dayTasks.where((t) => t.isDone).length;
                final score = total == 0 ? 0.0 : done / total;
                final isToday = now.day == day;

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: total == 0
                        ? cs.surfaceContainerLow
                        : cs.primary.withAlpha((score * 200 + 55).toInt()),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: cs.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: total == 0 ? cs.outline : Colors.white,
                          ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Monthly completion rate
            _StatCard(
              label: 'Avg Completion Rate',
              value: _monthlyRate(monthData),
              icon: Icons.donut_large,
              color: cs.primaryContainer,
              onColor: cs.onPrimaryContainer,
            ),
          ],
        );
      },
    );
  }

  String _monthlyRate(Map<int, List<Task>> data) {
    if (data.isEmpty) return '0%';
    final totals = data.values.expand((t) => t).toList();
    if (totals.isEmpty) return '0%';
    final done = totals.where((t) => t.isDone).length;
    return '${(done / totals.length * 100).toInt()}%';
  }
}

// ── Yearly Tab ────────────────────────────────────────────────────────────

class YearlyAnalyticsTab extends ConsumerWidget {
  const YearlyAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearAsync = ref.watch(yearlyTasksProvider);
    final cs = Theme.of(context).colorScheme;

    return yearAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (yearData) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('365-Day Overview',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: yearData.map((dayScore) {
                final alpha = (dayScore * 200 + 55).clamp(0, 255).toInt();
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dayScore == 0
                        ? cs.surfaceContainerLow
                        : cs.primary.withAlpha(alpha),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Monthly average bar chart
            Text('Monthly Averages',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    12,
                    (m) => BarChartGroupData(
                      x: m,
                      barRods: [
                        BarChartRodData(
                          toY: ref.watch(monthlyAvgProvider(m + 1)),
                          color: cs.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                          return Text(months[v.toInt()],
                              style: Theme.of(context).textTheme.labelSmall);
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shared Widget ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: onColor, size: 20),
              const SizedBox(height: AppSpacing.sm),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: onColor)),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: onColor)),
            ],
          ),
        ),
      ),
    );
  }
}
