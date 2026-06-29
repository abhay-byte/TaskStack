import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

/// Curated Material Symbols for goal/project selection.
const _kGoalIcons = [
  ('flag', Icons.flag_outlined),
  ('fitness_center', Icons.fitness_center_outlined),
  ('school', Icons.school_outlined),
  ('work', Icons.work_outline),
  ('code', Icons.code_outlined),
  ('palette', Icons.palette_outlined),
  ('music_note', Icons.music_note_outlined),
  ('menu_book', Icons.menu_book_outlined),
  ('savings', Icons.savings_outlined),
  ('flight', Icons.flight_outlined),
  ('home', Icons.home_outlined),
  ('family_restroom', Icons.family_restroom_outlined),
  ('self_improvement', Icons.self_improvement_outlined),
  ('language', Icons.language_outlined),
  ('eco', Icons.eco_outlined),
  ('pets', Icons.pets_outlined),
  ('restaurant', Icons.restaurant_outlined),
  ('directions_run', Icons.directions_run_outlined),
  ('construction', Icons.construction_outlined),
  ('business', Icons.business_outlined),
];

/// M3 semantic accent colours (matching task accent palette).
const _kAccentColors = [
  0xFFEF4444, // Red
  0xFFF97316, // Orange
  0xFFEAB308, // Yellow
  0xFF22C55E, // Green
  0xFF14B8A6, // Teal
  0xFF3B82F6, // Blue
  0xFF8B5CF6, // Violet
  0xFFEC4899, // Pink
  0xFFF43F5E, // Rose
  0xFF6366F1, // Indigo
  0xFF64748B, // Slate
  0xFF78716C, // Stone
];

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goalId});
  final String? goalId;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _titleCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  GoalType _selectedType = GoalType.project;
  bool _isGoal = true;
  bool _isSaving = false;
  bool _isLoading = false;
  String? _error;
  Goal? _existingGoal;
  String? _selectedIconId;
  int? _selectedColorArgb;

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      _loadGoal();
    }
  }

  Future<void> _loadGoal() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(goalRepositoryProvider);
      final goal = await repo.getGoalById(widget.goalId!);
      if (goal != null && mounted) {
        setState(() {
          _existingGoal = goal;
          _titleCtrl.text = goal.title;
          _selectedType = goal.type;
          _isGoal = goal.isGoal;
          _selectedIconId = goal.iconId;
          _selectedColorArgb = goal.colorArgb;

          if (goal.durationHours != null) {
            var remainingHours = goal.durationHours!;
            final years = remainingHours ~/ (365 * 24);
            remainingHours %= (365 * 24);
            final months = remainingHours ~/ (30 * 24);
            remainingHours %= (30 * 24);
            final days = remainingHours ~/ 24;

            _yearsCtrl.text = years > 0 ? years.toString() : '';
            _monthsCtrl.text = months > 0 ? months.toString() : '';
            _daysCtrl.text = days > 0 ? days.toString() : '';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load goal: \$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _daysCtrl.dispose();
    _monthsCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  int? _calculateDurationHours() {
    if (_selectedType == GoalType.noTime) return null;

    final days = int.tryParse(_daysCtrl.text) ?? 0;
    final months = int.tryParse(_monthsCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 0;

    final totalDays = days + (months * 30) + (years * 365);
    if (totalDays <= 0) return null;

    return totalDays * 24;
  }

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_selectedType != GoalType.noTime) {
      if (_calculateDurationHours() == null) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repository = ref.read(goalRepositoryProvider);
      final now = DateTime.now();

      final goal = Goal(
        id: _existingGoal?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        durationHours: _calculateDurationHours(),
        iconId: _selectedIconId,
        graphicImage: _existingGoal?.graphicImage,
        colorArgb: _selectedColorArgb,
        isGoal: _isGoal,
        createdAt: _existingGoal?.createdAt ?? now,
        updatedAt: now,
      );

      if (_existingGoal != null) {
        await repository.updateGoal(goal);
      } else {
        await repository.insertGoal(goal);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save goal: \$e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId == null ? 'New Goal' : 'Edit Goal'),
        actions: [
          if (_isSaving)
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
              onPressed: _isValid && !_isLoading ? _save : null,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Goal Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title *',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Is Goal toggle
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'This is a Goal (not just a Project)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Switch(
                      value: _isGoal,
                      onChanged: (v) => setState(() => _isGoal = v),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Goals track progress and time commitment. Projects are simpler containers.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Goal Type',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<GoalType>(
                    segments: const [
                      ButtonSegment(
                        value: GoalType.project,
                        label: Text('Project'),
                        icon: Icon(Icons.account_tree_outlined),
                      ),
                      ButtonSegment(
                        value: GoalType.habit,
                        label: Text('Habit'),
                        icon: Icon(Icons.repeat),
                      ),
                      ButtonSegment(
                        value: GoalType.noTime,
                        label: Text('Ongoing'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (s) => setState(() {
                      _selectedType = s.first;
                    }),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: cs.primaryContainer,
                      selectedForegroundColor: cs.onPrimaryContainer,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Icon picker
                Text(
                  'Icon',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _kGoalIcons.map((pair) {
                    final id = pair.$1;
                    final icon = pair.$2;
                    final isSelected = _selectedIconId == id;
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedIconId = isSelected ? null : id;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: cs.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Colour picker
                Text(
                  'Accent Colour',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _kAccentColors.map((colorValue) {
                    final isSelected = _selectedColorArgb == colorValue;
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedColorArgb =
                            isSelected ? null : colorValue;
                      }),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: cs.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white.withAlpha(200),
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Duration
                if (_selectedType != GoalType.noTime) ...[
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          color: cs.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Time to Complete',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Years',
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _monthsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Months',
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _daysCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Days',
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (_calculateDurationHours() != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: cs.secondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Total duration: ${_calculateDurationHours()} hours',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
