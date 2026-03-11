import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:taskstack/core/constants/app_spacing.dart';

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
  bool _isSaving = false;
  bool _isLoading = false;
  String? _error;
  Goal? _existingGoal;

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
          
          if (goal.durationHours != null) {
            // Simplified reverse calculation for the form
            int remainingHours = goal.durationHours!;
            int years = remainingHours ~/ (365 * 24);
            remainingHours %= (365 * 24);
            int months = remainingHours ~/ (30 * 24);
            remainingHours %= (30 * 24);
            int days = remainingHours ~/ 24;
            
            _yearsCtrl.text = years > 0 ? years.toString() : '';
            _monthsCtrl.text = months > 0 ? months.toString() : '';
            _daysCtrl.text = days > 0 ? days.toString() : '';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load goal: $e');
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
        createdAt: _existingGoal?.createdAt ?? now,
        updatedAt: now,
      );
      
      if (_existingGoal != null) {
        await repository.updateGoal(goal);
      } else {
        await repository.insertGoal(goal);
      }

      // Push to cloud immediately after local write
      ref.read(syncRepositoryProvider).pushLocalToCloud();

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save goal: $e';
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
        title: Text(widget.goalId == null ? 'New Goal/Project' : 'Edit Goal'),
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
                Text('Goal Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary)),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Goal Title *',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: cs.surface,
                  ),
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  'Goal Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary),
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

                // 2. Duration Details (If applicable)
                if (_selectedType != GoalType.noTime) ...[
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Time to Complete', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearsCtrl,
                          decoration: InputDecoration(
                            labelText: 'Years',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: cs.surface,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _monthsCtrl,
                          decoration: InputDecoration(
                            labelText: 'Months',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: cs.surface,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _daysCtrl,
                          decoration: InputDecoration(
                            labelText: 'Days',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: cs.surface,
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: cs.secondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Total duration: ${_calculateDurationHours()} hours',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
