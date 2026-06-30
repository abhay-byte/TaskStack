import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/constants/app_colors.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/settings/data/json_import_service.dart';
import 'package:taskstack/features/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile ───────────────────────────────────────────────────
          _SectionHeader('Profile'),

          _ProfileCard(
            onTap: () => context.push('/profile/me'),
          ),


          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader('Appearance'),

          // Theme toggle
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Auto')),
                ButtonSegment(value: 1, label: Text('Light')),
                ButtonSegment(value: 2, label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),

          // Accent colour
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Accent Colour'),
            subtitle: const Text('App primary brand colour'),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    settings.accentColorArgb != null
                        ? Color(settings.accentColorArgb!)
                        : cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outline),
              ),
            ),
            onTap: () => _showAccentPicker(context, ref, settings),
          ),

          // ── Format ────────────────────────────────────────────────────
          _SectionHeader('Format'),

          SwitchListTile(
            secondary: const Icon(Icons.schedule_outlined),
            title: const Text('24-Hour Time'),
            subtitle: const Text('Use 14:30 instead of 2:30 PM'),
            value: settings.use24HourTime,
            onChanged: notifier.setUse24HourTime,
          ),

          ListTile(
            leading: const Icon(Icons.calendar_view_week_outlined),
            title: const Text('Week Starts On'),
            trailing: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Sun')),
                ButtonSegment(value: false, label: Text('Mon')),
              ],
              selected: {settings.weekStartsSunday},
              onSelectionChanged: (s) => notifier.setWeekStartsSunday(s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),

          // ── Notifications ─────────────────────────────────────────────
          _SectionHeader('Notifications'),

          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('Default Reminder'),
            trailing: Text(
              '${settings.defaultNotificationOffsetMinutes} min before',
            ),
            onTap: () => _showReminderPicker(context, ref, settings),
          ),

          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test Notification'),
            onTap: () => _testNotification(context),
          ),

          // ── Data ──────────────────────────────────────────────────────
          _SectionHeader('Data'),

          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Data as JSON'),
            onTap: () => _exportData(context, ref),
          ),

          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import Data from JSON'),
            onTap: () => _importData(context, ref),
          ),

          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
            title: Text(
              'Clear Today\'s Tasks',
              style: TextStyle(color: cs.error),
            ),
            onTap: () => _clearToday(context, ref),
          ),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader('About'),

          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('Version'),
            trailing: const Text('1.0.4+5'),
          ),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licences'),
            onTap:
                () => showLicensePage(
                  context: context,
                  applicationName: 'TaskStack',
                ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showAccentPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final notifier = ref.read(settingsProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accent Colour',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    // Default (no override)
                    GestureDetector(
                      onTap: () {
                        notifier.setAccentColor(null);
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        child: const Icon(Icons.auto_awesome, size: 16),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                    ...AppColors.taskAccentColors.map(
                      (c) => GestureDetector(
                        onTap: () {
                          notifier.setAccentColor(c.value);
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundColor: c,
                          child:
                              settings.accentColorArgb == c.value
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
    );
  }

  void _showReminderPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final notifier = ref.read(settingsProvider.notifier);
    final options = [0, 5, 10, 15, 30];
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Default Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  options
                      .map(
                        (o) => RadioListTile<int>(
                          title: Text(
                            o == 0 ? 'At start time' : '$o min before',
                          ),
                          value: o,
                          groupValue: settings.defaultNotificationOffsetMinutes,
                          onChanged: (v) {
                            if (v != null) {
                              notifier.setDefaultNotificationOffset(v);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final now = DateTime.now();
      final tasks = await ref
          .read(taskRepositoryProvider)
          .getTasksInRange(DateTime(now.year - 5), DateTime(now.year + 5));
      final json = jsonEncode(tasks.map(_taskToJson).toList());
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/taskstack_export_${now.millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final importService = ref.read(jsonImportServiceProvider);
    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening file picker…'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    final count = await importService.importFromJson();
    if (!context.mounted) return;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected or no tasks to import')),
      );
    } else if (count == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Import failed — invalid JSON file'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $count task${count != 1 ? "s" : ""} successfully ✓',
          ),
        ),
      );
    }
  }

  Future<void> _clearToday(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Clear Today\'s Tasks'),
            content: const Text(
              'All tasks for today will be deleted. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final today = DateTime.now();
      final tasks = await ref
          .read(taskRepositoryProvider)
          .getTasksInRange(
            DateTime(today.year, today.month, today.day),
            DateTime(today.year, today.month, today.day),
          );
      for (final t in tasks) {
        await ref.read(deleteTaskUseCaseProvider).execute(t);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Today\'s tasks cleared')));
      }
    }
  }

  Map<String, dynamic> _taskToJson(Task t) => {
    'id': t.id,
    'title': t.title,
    'description': t.description,
    'purpose': t.purpose,
    'iconId': t.iconId,
    'colorArgb': t.colorArgb,
    'tags': t.tags,
    'startMinutes': t.startMinutes,
    'durationMinutes': t.durationMinutes,
    'recurrenceType': t.recurrenceType.name,
    'status': t.status.name,
    'taskDate': t.taskDate.toIso8601String(),
    'completedAt': t.completedAt?.toIso8601String(),
  };

  Future<void> _testNotification(BuildContext context) async {
    const androidDetails = AndroidNotificationDetails(
      'taskstack_test',
      'Test Notifications',
      channelDescription: 'Used for testing notifications',
      importance: Importance.max,
      priority: Priority.max,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    try {
      await NotificationService.plugin.show(
        id: 9999,
        title: 'Test Notification',
        body: 'This is a test notification from TaskStack!',
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Test notification sent')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test notification: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Local profile card ───────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Consumer(
      builder: (context, ref, _) {
        final prefs = ref.watch(sharedPreferencesProvider);
        final displayName = prefs.getString('profile_display_name') ?? '';
        final photoPath = prefs.getString('profile_photo_path');
        final hasPhoto =
            photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: cs.primaryContainer,
              backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
              child: !hasPhoto
                  ? (displayName.isNotEmpty
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Icon(Icons.person, color: cs.onPrimaryContainer))
                  : null,
            ),
            title: Text(
              displayName.isNotEmpty ? displayName : 'Local Profile',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              displayName.isNotEmpty
                  ? 'Tap to edit profile'
                  : 'Edit your display name & photo',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        );
      },
    );
  }
}
