import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/task_stack/presentation/providers/task_providers.dart';
import 'package:taskstack/core/constants/app_spacing.dart';
import 'package:taskstack/core/constants/app_colors.dart';
import 'package:taskstack/core/constants/task_graphics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

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
        children: [
          // ── Graphic Selection (At Top) ────────────────────────────────────
          _GraphicPicker(
            selectedGraphic: form.graphicImage,
            onSelected: notifier.updateGraphicImage,
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),

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
                Text(
                  'Accent Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
                    notifier.updateTags(
                      form.tags.where((t) => t != tag).toList(),
                    );
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
                      notifier.updateStartMinutes(
                        picked.hour * 60 + picked.minute,
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── End Time ──────────────────────────────────────────────────────
                _FormSection(
                  icon: Icons.timer_off_outlined,
                  label: 'End Time',
                  value: () {
                    final start = form.startMinutes;
                    final dur = form.durationMinutes;
                    if (start == null) return 'Set start time first';
                    final endM = (start + dur) % (24 * 60);
                    final h = endM ~/ 60;
                    final min = endM % 60;
                    final period = h < 12 ? 'AM' : 'PM';
                    final displayH = h % 12 == 0 ? 12 : h % 12;
                    return '${displayH.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
                  }(),
                  onTap:
                      form.startMinutes == null
                          ? null
                          : () async {
                            final startM = form.startMinutes!;
                            final currentEndM = startM + form.durationMinutes;
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: (currentEndM ~/ 60) % 24,
                                minute: currentEndM % 60,
                              ),
                              helpText: 'Select end time',
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
                              final endM = picked.hour * 60 + picked.minute;
                              var duration = endM - startM;
                              if (duration <= 0)
                                duration += 24 * 60; // next day
                              notifier.updateDuration(duration);
                            }
                          },
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Recurrence ────────────────────────────────────────────────────
                Text(
                  'Recurrence',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<RecurrenceType>(
                    segments: const [
                      ButtonSegment(
                        value: RecurrenceType.none,
                        label: Text('None'),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.repeatToday,
                        label: Text('Today'),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.daily,
                        label: Text('Daily'),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.weekly,
                        label: Text('Weekly'),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.custom,
                        label: Text('Custom'),
                      ),
                    ],
                    selected: {form.recurrenceType},
                    onSelectionChanged:
                        (s) => notifier.updateRecurrence(s.first),
                  ),
                ),
                if (form.recurrenceType == RecurrenceType.custom) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDayChip(1, 'M', form, notifier),
                      _buildDayChip(2, 'T', form, notifier),
                      _buildDayChip(3, 'W', form, notifier),
                      _buildDayChip(4, 'T', form, notifier),
                      _buildDayChip(5, 'F', form, notifier),
                      _buildDayChip(6, 'S', form, notifier),
                      _buildDayChip(7, 'S', form, notifier),
                    ],
                  ),
                ],
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

    RecurringScope scope = RecurringScope.thisInstance;
    if (widget.taskId != null) {
      final isRecurring =
          form.recurrenceType != RecurrenceType.none ||
          form.parentTaskId != null;
      if (isRecurring) {
        final selectedScope = await _confirmRecurringEdit(context);
        if (selectedScope == null) return;
        scope = selectedScope;
      }
    }

    final success = await ref
        .read(taskFormProvider.notifier)
        .save(date, scope: scope);
    if (success && context.mounted) context.pop();
  }

  Future<RecurringScope?> _confirmRecurringEdit(BuildContext context) async {
    return await showDialog<RecurringScope>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit Recurring Task'),
            content: const Text(
              'Do you want to apply these changes to this instance only, or to all upcoming instances?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(ctx, RecurringScope.thisInstance),
                child: const Text('This instance only'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(ctx, RecurringScope.futureInstances),
                child: const Text('All upcoming'),
              ),
            ],
          ),
    );
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

  Widget _buildDayChip(
    int day,
    String label,
    TaskFormState form,
    TaskFormNotifier notifier,
  ) {
    final isSelected = form.customRecurrenceDays.contains(day);
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.toggleCustomDay(day),
      showCheckmark: false,
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(AppSpacing.sm),
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
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
  final VoidCallback? onTap;

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

class _GraphicPicker extends StatelessWidget {
  const _GraphicPicker({this.selectedGraphic, required this.onSelected});
  final String? selectedGraphic;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGraphicSelector(context),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color:
                  selectedGraphic != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child:
            selectedGraphic == null
                ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined),
                      SizedBox(height: 4),
                      Text('Select Graphic'),
                    ],
                  ),
                )
                : Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: _GraphicWebView(assetPath: selectedGraphic!),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => onSelected(null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _showGraphicSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                AppBar(
                  title: const Text('Choose Graphic'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio:
                              4 / 3, // Matches the 400x300 SVG ratio
                        ),
                    itemCount: TaskGraphics.availableGraphics.length,
                    itemBuilder: (ctx, index) {
                      final graphic = TaskGraphics.availableGraphics[index];
                      final isSelected = graphic == selectedGraphic;
                      return GestureDetector(
                        onTap: () {
                          onSelected(graphic);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(graphic),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainer,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(9),
                                  ),
                                ),
                                child: Text(
                                  TaskGraphics.getDisplayName(graphic),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GraphicWebView extends StatefulWidget {
  const _GraphicWebView({required this.assetPath});
  final String assetPath;

  @override
  State<_GraphicWebView> createState() => _GraphicWebViewState();
}

class _GraphicWebViewState extends State<_GraphicWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent);
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    try {
      final svgString = await rootBundle.loadString(widget.assetPath);
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body, html { 
      margin: 0; padding: 0; width: 100%; height: 100%; 
      overflow: hidden; background-color: transparent; 
      display: flex; justify-content: center; align-items: center; 
    }
    svg { 
      width: 100%; height: 100%; 
    }
  </style>
</head>
<body>
  \$svgString
  <script>
    const svg = document.querySelector('svg');
    if (svg) {
      svg.setAttribute('preserveAspectRatio', 'xMidYMid slice');
    }
  </script>
</body>
</html>
      ''';
      if (mounted) {
        _controller.loadHtmlString(html);
      }
    } catch (e) {
      debugPrint('Error loading SVG for WebView: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
