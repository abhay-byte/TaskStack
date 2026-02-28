import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';

class JsonImportService {
  JsonImportService(this._repo);
  final TaskRepository _repo;

  /// Opens a file picker, reads the JSON, and imports all tasks.
  /// Returns the number of tasks imported, or -1 on failure.
  Future<int> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return 0;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        // Fallback to path-based read on platforms that provide a path
        final path = file.path;
        if (path == null) return -1;
        final content = await File(path).readAsString();
        return _parseAndInsert(content);
      }
      return _parseAndInsert(utf8.decode(bytes));
    } catch (e) {
      return -1;
    }
  }

  Future<int> _parseAndInsert(String jsonStr) async {
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    int imported = 0;

    for (final map in list) {
      try {
        final m = map as Map<String, dynamic>;
        final existing = await _repo.getTaskById(m['id'] as String);
        if (existing != null) continue; // skip duplicates

        final task = Task(
          id: m['id'] as String,
          title: m['title'] as String,
          description: m['description'] as String?,
          purpose: m['purpose'] as String?,
          iconId: m['iconId'] as String?,
          colorArgb: m['colorArgb'] as int?,
          tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          startMinutes: m['startMinutes'] as int?,
          durationMinutes: m['durationMinutes'] as int?,
          recurrenceType: RecurrenceType.values.firstWhere(
            (e) => e.name == (m['recurrenceType'] ?? 'none'),
            orElse: () => RecurrenceType.none,
          ),
          status: TaskStatus.values.firstWhere(
            (e) => e.name == (m['status'] ?? 'pending'),
            orElse: () => TaskStatus.pending,
          ),
          completedAt: m['completedAt'] != null
              ? DateTime.parse(m['completedAt'] as String)
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskDate: DateTime.parse(m['taskDate'] as String),
        );

        await _repo.insertTask(task);
        imported++;
      } catch (_) {
        continue; // Skip malformed entries
      }
    }

    return imported;
  }
}

final jsonImportServiceProvider = Provider<JsonImportService>((ref) {
  return JsonImportService(ref.watch(taskRepositoryProvider));
});
