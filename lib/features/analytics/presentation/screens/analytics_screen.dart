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
        final mostProductiveHour = hourly.indexOf(
          hourly.reduce((a, b) => a > b ? a : b),
        );

        // Tag distribution
        final tagCounts = <String, int>{};
        for (final t in tasks) {
          for (final tag in t.tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }

        final completedTasks = tasks.where((t) => t.isDone).toList();

        final cs = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Completed tasks donut (Hero style)
            if (completedTasks.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: cs.outlineVariant.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.stars_rounded,
                              color: cs.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Completed By You',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 45,
                            sections:
                                completedTasks.asMap().entries.map((e) {
                                  final colors = [
                                    cs.primary,
                                    cs.tertiary,
                                    cs.secondary,
                                    cs.error,
                                    cs.primaryContainer,
                                  ];
                                  final task = e.value;
                                  final title =
                                      task.title.length > 12
                                          ? '${task.title.substring(0, 10)}...'
                                          : task.title;
                                  return PieChartSectionData(
                                    value:
                                        (task.durationMinutes ?? 30).toDouble(),
                                    title: title,
                                    color: colors[e.key % colors.length],
                                    radius: 75,
                                    titlePositionPercentageOffset: 0.6,
                                    titleStyle: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

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

            // Most productive hour (Hero Banner)
            if (total > 0)
              Card(
                elevation: 0,
                color: cs.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.onSecondaryContainer.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bolt,
                          color: cs.onSecondaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Most Active Hour',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'When you schedule the most tasks',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSecondaryContainer),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        mostProductiveHour < 12
                            ? (mostProductiveHour == 0
                                ? '12 AM'
                                : '$mostProductiveHour AM')
                            : (mostProductiveHour == 12
                                ? '12 PM'
                                : '${mostProductiveHour - 12} PM'),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (total > 0) const SizedBox(height: AppSpacing.xl),

            // Hourly bar chart
            if (total > 0) ...[
              Text(
                'Hourly Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 180,
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
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY:
                                  hourly
                                      .reduce((a, b) => a > b ? a : b)
                                      .toDouble() *
                                  1.1,
                              color: cs.surfaceContainerHighest.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 6,
                          getTitlesWidget: (v, _) {
                            final h = v.toInt();
                            if (h == 0) return _ChartLabel('12 AM', context);
                            if (h == 6) return _ChartLabel('6 AM', context);
                            if (h == 12) return _ChartLabel('12 PM', context);
                            if (h == 18) return _ChartLabel('6 PM', context);
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: cs.outlineVariant.withAlpha(50),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                    ),
                    borderData: FlBorderData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Tag donut
            if (tagCounts.isNotEmpty) ...[
              Text(
                'Tag Distribution',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    sections:
                        tagCounts.entries.toList().asMap().entries.map((e) {
                          final colors = [
                            cs.primary,
                            cs.secondary,
                            cs.tertiary,
                            cs.error,
                            cs.outline,
                          ];
                          return PieChartSectionData(
                            value: e.value.value.toDouble(),
                            title: e.value.key,
                            color: colors[e.key % colors.length],
                            radius: 70,
                            titleStyle: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
            ],

            if (total == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text('No tasks scheduled for this day.'),
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
        final dones =
            weekData.map((d) => d.where((t) => t.isDone).length).toList();
        final labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
        final scores = List.generate(
          7,
          (i) => totals[i] == 0 ? 0.0 : (dones[i] / totals[i]) * 100,
        );
        final bestDay = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Best day (Hero Banner)
            Card(
              elevation: 0,
              color: cs.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.onSecondaryContainer.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_outline,
                        color: cs.onSecondaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best Day',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your most productive weekday',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSecondaryContainer),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      labels[bestDay],
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Tasks Completed per Day',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
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
                          width: 24,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: totals[i] > 0 ? totals[i].toDouble() : 1.0,
                            color: cs.surfaceContainerHighest.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget:
                            (v, _) => _ChartLabel(labels[v.toInt()], context),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: cs.outlineVariant.withAlpha(50),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Productivity Score (0–100)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(7, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        labels[i],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: scores[i] / 100,
                          minHeight: 12,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${scores[i].toInt()}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Monthly completion rate
            Row(
              children: [
                _StatCard(
                  label: 'Monthly Rate',
                  value: _monthlyRate(monthData),
                  icon: Icons.donut_large,
                  color: cs.primaryContainer,
                  onColor: cs.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatCard(
                  label: 'Days Active',
                  value: '${monthData.keys.length}',
                  icon: Icons.local_fire_department_outlined,
                  color: cs.tertiaryContainer,
                  onColor: cs.onTertiaryContainer,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'This Month',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, i) {
                final day = i + 1;
                final dayTasks = monthData[day] ?? [];
                final total = dayTasks.length;
                final done = dayTasks.where((t) => t.isDone).length;
                final score = total == 0 ? 0.0 : done / total;
                final isToday = now.day == day;

                return Container(
                  decoration: BoxDecoration(
                    color:
                        total == 0
                            ? cs.surfaceContainerLow
                            : cs.primary.withAlpha((score * 200 + 55).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isToday
                            ? Border.all(color: cs.primary, width: 2)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: total == 0 ? cs.onSurfaceVariant : Colors.white,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '365-Day Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  yearData.map((dayScore) {
                    final alpha = (dayScore * 200 + 55).clamp(0, 255).toInt();
                    return Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color:
                            dayScore == 0
                                ? cs.surfaceContainerLow
                                : cs.primary.withAlpha(alpha),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Monthly average bar chart
            Text(
              'Monthly Averages',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
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
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100, // percentage base
                            color: cs.surfaceContainerHighest.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          return _ChartLabel(months[v.toInt()], context);
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: cs.outlineVariant.withAlpha(50),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceAround,
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
        elevation: 0,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: onColor, size: 24),
              const SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: onColor.withAlpha(200),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel(this.text, this.context);
  final String text;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
