import 'package:drift/drift.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/tables/tags_table.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [TagsTable])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<TagsTableData>> watchAllTags() => select(tagsTable).watch();

  Future<List<TagsTableData>> getAllTags() => select(tagsTable).get();

  Future<void> insertTag(TagsTableCompanion tag) =>
      into(tagsTable).insertOnConflictUpdate(tag);

  Future<int> deleteTag(String id) =>
      (delete(tagsTable)..where((t) => t.id.equals(id))).go();
}
