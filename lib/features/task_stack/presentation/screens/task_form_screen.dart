import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/constants/app_colors.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId, this.prefilledDate});
  final String? taskId;
  final DateTime? prefilledDate;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
  }

  Future<void> _loadTask() async {
    if (widget.taskId == null) {
      // Pre-fill start time with current if new task
      final now = DateTime.now();
      ref
          .read(taskFormProvider.notifier)
          .updateStartMinutes(now.hour * 60 + now.minute);
      setState(() => _loaded = true);
      return;
    }
    final date = ref.read(selectedStackDateProvider);
    final tasks = await ref.read(tasksForDateProvider(date).future);
    final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task != null) {
      ref.read(taskFormProvider.notifier).loadTask(task);
      _titleCtrl.text = task.title;
      _descCtrl.text = task.description ?? '';
      _purposeCtrl.text = task.purpose ?? '';
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _purposeCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(taskFormProvider);
    final notifier = ref.read(taskFormProvider.notifier);
    final isEdit = widget.taskId != null;
    final cs = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'New Task'),
        actions: [
          if (form.isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: form.isValid ? () => _save(context, form) : null,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Title ───────────────────────────────────────────────────────
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Task title *',
              helperText: 'Max 80 characters',
              border: OutlineInputBorder(),
            ),
            maxLength: 80,
            onChanged: notifier.updateTitle,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Description ─────────────────────────────────────────────────
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
            onChanged: notifier.updateDescription,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Purpose ──────────────────────────────────────────────────────
          TextField(
            controller: _purposeCtrl,
            decoration: const InputDecoration(
              labelText: 'Purpose (the why)',
              helperText: 'Why is this task important to you?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
            maxLength: 200,
            onChanged: notifier.updatePurpose,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Accent Colour ─────────────────────────────────────────────────
          Text('Accent Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _ColorPicker(
            selectedColor:
                form.colorArgb != null ? Color(form.colorArgb!) : null,
            onSelected: (c) => notifier.updateColor(c?.toARGB32()),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Tags ──────────────────────────────────────────────────────────
          Text('Tags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _TagInput(
            controller: _tagCtrl,
            tags: form.tags,
            onAdd: (tag) {
              if (form.tags.length < 5 && !form.tags.contains(tag)) {
                notifier.updateTags([...form.tags, tag]);
              }
              _tagCtrl.clear();
            },
            onRemove: (tag) {
              notifier.updateTags(form.tags.where((t) => t != tag).toList());
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Start Time ────────────────────────────────────────────────────
          _FormSection(
            icon: Icons.access_time,
            label: 'Start Time',
            value:
                form.startMinutes != null
                    ? _minutesToLabel(form.startMinutes!)
                    : 'Not set',
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    form.startMinutes != null
                        ? TimeOfDay(
                          hour: form.startMinutes! ~/ 60,
                          minute: form.startMinutes! % 60,
                        )
                        : TimeOfDay.now(),
                initialEntryMode: TimePickerEntryMode.dial,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                notifier.updateStartMinutes(picked.hour * 60 + picked.minute);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Duration ──────────────────────────────────────────────────────
          _FormSection(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '${form.durationMinutes} minutes',
            onTap: () => _showDurationPicker(context, form, notifier),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Recurrence ────────────────────────────────────────────────────
          Text('Recurrence', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<RecurrenceType>(
            segments: const [
              ButtonSegment(value: RecurrenceType.none, label: Text('None')),
              ButtonSegment(
                value: RecurrenceType.repeatToday,
                label: Text('Today'),
              ),
              ButtonSegment(value: RecurrenceType.daily, label: Text('Daily')),
              ButtonSegment(
                value: RecurrenceType.weekly,
                label: Text('Weekly'),
              ),
            ],
            selected: {form.recurrenceType},
            onSelectionChanged: (s) => notifier.updateRecurrence(s.first),
          ),
          if (form.recurrenceType == RecurrenceType.repeatToday) ...[
            const SizedBox(height: AppSpacing.sm),
            _FormSection(
              icon: Icons.repeat,
              label: 'Repeat every',
              value: '${form.repeatIntervalMinutes} minutes',
              onTap: () => _showIntervalPicker(context, form, notifier),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // ── Notifications ─────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Notification'),
            subtitle: const Text('Get reminded before this task'),
            value: form.notificationEnabled,
            onChanged: notifier.updateNotificationEnabled,
            secondary: const Icon(Icons.notifications_outlined),
            contentPadding: EdgeInsets.zero,
          ),
          if (form.notificationEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            _FormSection(
              icon: Icons.alarm,
              label: 'Remind me',
              value: _offsetLabel(form.notificationOffsetMinutes),
              onTap: () => _showOffsetPicker(context, form, notifier),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          if (form.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(form.error!, style: TextStyle(color: cs.error)),
            ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, TaskFormState form) async {
    final DateTime date;
    if (widget.prefilledDate != null) {
      date = widget.prefilledDate!;
    } else {
      date = ref.read(selectedStackDateProvider);
    }
    final success = await ref.read(taskFormProvider.notifier).save(date);
    if (success && context.mounted) context.pop();
  }

  String _minutesToLabel(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${min.toString().padLeft(2, '0')} $period';
  }

  String _offsetLabel(int minutes) => switch (minutes) {
    0 => 'At start time',
    5 => '5 minutes before',
    10 => '10 minutes before',
    15 => '15 minutes before',
    30 => '30 minutes before',
    _ => '$minutes minutes before',
  };

  void _showDurationPicker(
    BuildContext context,
    TaskFormState form,
    TaskFormNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => _NumberPickerDialog(
            title: 'Duration (minutes)',
            options: [15, 30, 45, 60, 90, 120, 180, 240],
            selected: form.durationMinutes,
            onSelected: notifier.updateDuration,
          ),
    );
  }

  void _showIntervalPicker(
    BuildContext context,
    TaskFormState form,
    TaskFormNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => _NumberPickerDialog(
            title: 'Repeat every N minutes',
            options: [15, 30, 60, 90, 120],
            selected: form.repeatIntervalMinutes,
            onSelected: notifier.updateRepeatInterval,
          ),
    );
  }

  void _showOffsetPicker(
    BuildContext context,
    TaskFormState form,
    TaskFormNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => _NumberPickerDialog(
            title: 'Reminder',
            options: [0, 5, 10, 15, 30],
            selected: form.notificationOffsetMinutes,
            onSelected: notifier.updateNotificationOffset,
            labelBuilder: (n) => n == 0 ? 'At start time' : '$n min before',
          ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({this.selectedColor, required this.onSelected});
  final Color? selectedColor;
  final void Function(Color?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        // None option
        GestureDetector(
          onTap: () => onSelected(null),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    selectedColor == null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                width: selectedColor == null ? 3 : 1,
              ),
            ),
            child: const Icon(Icons.block, size: 18),
          ),
        ),
        ...AppColors.taskAccentColors.map(
          (c) => GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selectedColor?.toARGB32() == c.toARGB32()
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagInput extends StatelessWidget {
  const _TagInput({
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> tags;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Add tag (max 5)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final t = controller.text.trim().toLowerCase();
                if (t.isNotEmpty) onAdd(t);
              },
            ),
          ),
          onSubmitted: (v) {
            final t = v.trim().toLowerCase();
            if (t.isNotEmpty) onAdd(t);
          },
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children:
                tags
                    .map(
                      (tag) => InputChip(
                        label: Text('#$tag'),
                        onDeleted: () => onRemove(tag),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }
}

class _NumberPickerDialog extends StatelessWidget {
  const _NumberPickerDialog({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final String title;
  final List<int> options;
  final int selected;
  final void Function(int) onSelected;
  final String Function(int)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            options
                .map(
                  (o) => RadioListTile<int>(
                    title: Text(labelBuilder != null ? labelBuilder!(o) : '$o'),
                    value: o,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) {
                        onSelected(v);
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
                .toList(),
      ),
    );
  }
}
