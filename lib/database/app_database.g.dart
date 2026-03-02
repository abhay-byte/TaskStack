// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTableTable extends TasksTable
    with TableInfo<$TasksTableTable, TasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconIdMeta = const VerificationMeta('iconId');
  @override
  late final GeneratedColumn<String> iconId = GeneratedColumn<String>(
    'icon_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _graphicImageMeta = const VerificationMeta(
    'graphicImage',
  );
  @override
  late final GeneratedColumn<String> graphicImage = GeneratedColumn<String>(
    'graphic_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceTypeMeta = const VerificationMeta(
    'recurrenceType',
  );
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatIntervalMinutesMeta =
      const VerificationMeta('repeatIntervalMinutes');
  @override
  late final GeneratedColumn<int> repeatIntervalMinutes = GeneratedColumn<int>(
    'repeat_interval_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationEnabledMeta =
      const VerificationMeta('notificationEnabled');
  @override
  late final GeneratedColumn<bool> notificationEnabled = GeneratedColumn<bool>(
    'notification_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notification_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notificationOffsetMinutesMeta =
      const VerificationMeta('notificationOffsetMinutes');
  @override
  late final GeneratedColumn<int> notificationOffsetMinutes =
      GeneratedColumn<int>(
        'notification_offset_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(5),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskDateMeta = const VerificationMeta(
    'taskDate',
  );
  @override
  late final GeneratedColumn<String> taskDate = GeneratedColumn<String>(
    'task_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    purpose,
    iconId,
    colorArgb,
    graphicImage,
    tagsJson,
    startMinutes,
    durationMinutes,
    recurrenceType,
    recurrenceRule,
    repeatIntervalMinutes,
    notificationEnabled,
    notificationOffsetMinutes,
    status,
    completedAt,
    createdAt,
    updatedAt,
    parentTaskId,
    goalId,
    taskDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    }
    if (data.containsKey('icon_id')) {
      context.handle(
        _iconIdMeta,
        iconId.isAcceptableOrUnknown(data['icon_id']!, _iconIdMeta),
      );
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    }
    if (data.containsKey('graphic_image')) {
      context.handle(
        _graphicImageMeta,
        graphicImage.isAcceptableOrUnknown(
          data['graphic_image']!,
          _graphicImageMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
        _recurrenceTypeMeta,
        recurrenceType.isAcceptableOrUnknown(
          data['recurrence_type']!,
          _recurrenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('repeat_interval_minutes')) {
      context.handle(
        _repeatIntervalMinutesMeta,
        repeatIntervalMinutes.isAcceptableOrUnknown(
          data['repeat_interval_minutes']!,
          _repeatIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('notification_enabled')) {
      context.handle(
        _notificationEnabledMeta,
        notificationEnabled.isAcceptableOrUnknown(
          data['notification_enabled']!,
          _notificationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notification_offset_minutes')) {
      context.handle(
        _notificationOffsetMinutesMeta,
        notificationOffsetMinutes.isAcceptableOrUnknown(
          data['notification_offset_minutes']!,
          _notificationOffsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('task_date')) {
      context.handle(
        _taskDateMeta,
        taskDate.isAcceptableOrUnknown(data['task_date']!, _taskDateMeta),
      );
    } else if (isInserting) {
      context.missing(_taskDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasksTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      ),
      iconId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_id'],
      ),
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      ),
      graphicImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}graphic_image'],
      ),
      tagsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tags_json'],
          )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      recurrenceType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}recurrence_type'],
          )!,
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      repeatIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_interval_minutes'],
      ),
      notificationEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}notification_enabled'],
          )!,
      notificationOffsetMinutes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}notification_offset_minutes'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      taskDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}task_date'],
          )!,
    );
  }

  @override
  $TasksTableTable createAlias(String alias) {
    return $TasksTableTable(attachedDatabase, alias);
  }
}

class TasksTableData extends DataClass implements Insertable<TasksTableData> {
  final String id;
  final String title;
  final String? description;
  final String? purpose;
  final String? iconId;
  final int? colorArgb;
  final String? graphicImage;
  final String tagsJson;
  final int? startMinutes;
  final int? durationMinutes;
  final String recurrenceType;
  final String? recurrenceRule;
  final int? repeatIntervalMinutes;
  final bool notificationEnabled;
  final int notificationOffsetMinutes;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentTaskId;
  final String? goalId;
  final String taskDate;
  const TasksTableData({
    required this.id,
    required this.title,
    this.description,
    this.purpose,
    this.iconId,
    this.colorArgb,
    this.graphicImage,
    required this.tagsJson,
    this.startMinutes,
    this.durationMinutes,
    required this.recurrenceType,
    this.recurrenceRule,
    this.repeatIntervalMinutes,
    required this.notificationEnabled,
    required this.notificationOffsetMinutes,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    this.goalId,
    required this.taskDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    if (!nullToAbsent || iconId != null) {
      map['icon_id'] = Variable<String>(iconId);
    }
    if (!nullToAbsent || colorArgb != null) {
      map['color_argb'] = Variable<int>(colorArgb);
    }
    if (!nullToAbsent || graphicImage != null) {
      map['graphic_image'] = Variable<String>(graphicImage);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    if (!nullToAbsent || startMinutes != null) {
      map['start_minutes'] = Variable<int>(startMinutes);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['recurrence_type'] = Variable<String>(recurrenceType);
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || repeatIntervalMinutes != null) {
      map['repeat_interval_minutes'] = Variable<int>(repeatIntervalMinutes);
    }
    map['notification_enabled'] = Variable<bool>(notificationEnabled);
    map['notification_offset_minutes'] = Variable<int>(
      notificationOffsetMinutes,
    );
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    map['task_date'] = Variable<String>(taskDate);
    return map;
  }

  TasksTableCompanion toCompanion(bool nullToAbsent) {
    return TasksTableCompanion(
      id: Value(id),
      title: Value(title),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      purpose:
          purpose == null && nullToAbsent
              ? const Value.absent()
              : Value(purpose),
      iconId:
          iconId == null && nullToAbsent ? const Value.absent() : Value(iconId),
      colorArgb:
          colorArgb == null && nullToAbsent
              ? const Value.absent()
              : Value(colorArgb),
      graphicImage:
          graphicImage == null && nullToAbsent
              ? const Value.absent()
              : Value(graphicImage),
      tagsJson: Value(tagsJson),
      startMinutes:
          startMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(startMinutes),
      durationMinutes:
          durationMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(durationMinutes),
      recurrenceType: Value(recurrenceType),
      recurrenceRule:
          recurrenceRule == null && nullToAbsent
              ? const Value.absent()
              : Value(recurrenceRule),
      repeatIntervalMinutes:
          repeatIntervalMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(repeatIntervalMinutes),
      notificationEnabled: Value(notificationEnabled),
      notificationOffsetMinutes: Value(notificationOffsetMinutes),
      status: Value(status),
      completedAt:
          completedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      parentTaskId:
          parentTaskId == null && nullToAbsent
              ? const Value.absent()
              : Value(parentTaskId),
      goalId:
          goalId == null && nullToAbsent ? const Value.absent() : Value(goalId),
      taskDate: Value(taskDate),
    );
  }

  factory TasksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasksTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      purpose: serializer.fromJson<String?>(json['purpose']),
      iconId: serializer.fromJson<String?>(json['iconId']),
      colorArgb: serializer.fromJson<int?>(json['colorArgb']),
      graphicImage: serializer.fromJson<String?>(json['graphicImage']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      startMinutes: serializer.fromJson<int?>(json['startMinutes']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      recurrenceType: serializer.fromJson<String>(json['recurrenceType']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      repeatIntervalMinutes: serializer.fromJson<int?>(
        json['repeatIntervalMinutes'],
      ),
      notificationEnabled: serializer.fromJson<bool>(
        json['notificationEnabled'],
      ),
      notificationOffsetMinutes: serializer.fromJson<int>(
        json['notificationOffsetMinutes'],
      ),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      taskDate: serializer.fromJson<String>(json['taskDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'purpose': serializer.toJson<String?>(purpose),
      'iconId': serializer.toJson<String?>(iconId),
      'colorArgb': serializer.toJson<int?>(colorArgb),
      'graphicImage': serializer.toJson<String?>(graphicImage),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'startMinutes': serializer.toJson<int?>(startMinutes),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'recurrenceType': serializer.toJson<String>(recurrenceType),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'repeatIntervalMinutes': serializer.toJson<int?>(repeatIntervalMinutes),
      'notificationEnabled': serializer.toJson<bool>(notificationEnabled),
      'notificationOffsetMinutes': serializer.toJson<int>(
        notificationOffsetMinutes,
      ),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'goalId': serializer.toJson<String?>(goalId),
      'taskDate': serializer.toJson<String>(taskDate),
    };
  }

  TasksTableData copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> purpose = const Value.absent(),
    Value<String?> iconId = const Value.absent(),
    Value<int?> colorArgb = const Value.absent(),
    Value<String?> graphicImage = const Value.absent(),
    String? tagsJson,
    Value<int?> startMinutes = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    String? recurrenceType,
    Value<String?> recurrenceRule = const Value.absent(),
    Value<int?> repeatIntervalMinutes = const Value.absent(),
    bool? notificationEnabled,
    int? notificationOffsetMinutes,
    String? status,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> parentTaskId = const Value.absent(),
    Value<String?> goalId = const Value.absent(),
    String? taskDate,
  }) => TasksTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    purpose: purpose.present ? purpose.value : this.purpose,
    iconId: iconId.present ? iconId.value : this.iconId,
    colorArgb: colorArgb.present ? colorArgb.value : this.colorArgb,
    graphicImage: graphicImage.present ? graphicImage.value : this.graphicImage,
    tagsJson: tagsJson ?? this.tagsJson,
    startMinutes: startMinutes.present ? startMinutes.value : this.startMinutes,
    durationMinutes:
        durationMinutes.present ? durationMinutes.value : this.durationMinutes,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    recurrenceRule:
        recurrenceRule.present ? recurrenceRule.value : this.recurrenceRule,
    repeatIntervalMinutes:
        repeatIntervalMinutes.present
            ? repeatIntervalMinutes.value
            : this.repeatIntervalMinutes,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    notificationOffsetMinutes:
        notificationOffsetMinutes ?? this.notificationOffsetMinutes,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    goalId: goalId.present ? goalId.value : this.goalId,
    taskDate: taskDate ?? this.taskDate,
  );
  TasksTableData copyWithCompanion(TasksTableCompanion data) {
    return TasksTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      iconId: data.iconId.present ? data.iconId.value : this.iconId,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      graphicImage:
          data.graphicImage.present
              ? data.graphicImage.value
              : this.graphicImage,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      startMinutes:
          data.startMinutes.present
              ? data.startMinutes.value
              : this.startMinutes,
      durationMinutes:
          data.durationMinutes.present
              ? data.durationMinutes.value
              : this.durationMinutes,
      recurrenceType:
          data.recurrenceType.present
              ? data.recurrenceType.value
              : this.recurrenceType,
      recurrenceRule:
          data.recurrenceRule.present
              ? data.recurrenceRule.value
              : this.recurrenceRule,
      repeatIntervalMinutes:
          data.repeatIntervalMinutes.present
              ? data.repeatIntervalMinutes.value
              : this.repeatIntervalMinutes,
      notificationEnabled:
          data.notificationEnabled.present
              ? data.notificationEnabled.value
              : this.notificationEnabled,
      notificationOffsetMinutes:
          data.notificationOffsetMinutes.present
              ? data.notificationOffsetMinutes.value
              : this.notificationOffsetMinutes,
      status: data.status.present ? data.status.value : this.status,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      parentTaskId:
          data.parentTaskId.present
              ? data.parentTaskId.value
              : this.parentTaskId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      taskDate: data.taskDate.present ? data.taskDate.value : this.taskDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('purpose: $purpose, ')
          ..write('iconId: $iconId, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('graphicImage: $graphicImage, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('repeatIntervalMinutes: $repeatIntervalMinutes, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('notificationOffsetMinutes: $notificationOffsetMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('goalId: $goalId, ')
          ..write('taskDate: $taskDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    purpose,
    iconId,
    colorArgb,
    graphicImage,
    tagsJson,
    startMinutes,
    durationMinutes,
    recurrenceType,
    recurrenceRule,
    repeatIntervalMinutes,
    notificationEnabled,
    notificationOffsetMinutes,
    status,
    completedAt,
    createdAt,
    updatedAt,
    parentTaskId,
    goalId,
    taskDate,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasksTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.purpose == this.purpose &&
          other.iconId == this.iconId &&
          other.colorArgb == this.colorArgb &&
          other.graphicImage == this.graphicImage &&
          other.tagsJson == this.tagsJson &&
          other.startMinutes == this.startMinutes &&
          other.durationMinutes == this.durationMinutes &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceRule == this.recurrenceRule &&
          other.repeatIntervalMinutes == this.repeatIntervalMinutes &&
          other.notificationEnabled == this.notificationEnabled &&
          other.notificationOffsetMinutes == this.notificationOffsetMinutes &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.parentTaskId == this.parentTaskId &&
          other.goalId == this.goalId &&
          other.taskDate == this.taskDate);
}

class TasksTableCompanion extends UpdateCompanion<TasksTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> purpose;
  final Value<String?> iconId;
  final Value<int?> colorArgb;
  final Value<String?> graphicImage;
  final Value<String> tagsJson;
  final Value<int?> startMinutes;
  final Value<int?> durationMinutes;
  final Value<String> recurrenceType;
  final Value<String?> recurrenceRule;
  final Value<int?> repeatIntervalMinutes;
  final Value<bool> notificationEnabled;
  final Value<int> notificationOffsetMinutes;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> parentTaskId;
  final Value<String?> goalId;
  final Value<String> taskDate;
  final Value<int> rowid;
  const TasksTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.purpose = const Value.absent(),
    this.iconId = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.graphicImage = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.repeatIntervalMinutes = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.notificationOffsetMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.taskDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.purpose = const Value.absent(),
    this.iconId = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.graphicImage = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.repeatIntervalMinutes = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.notificationOffsetMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.parentTaskId = const Value.absent(),
    this.goalId = const Value.absent(),
    required String taskDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       taskDate = Value(taskDate);
  static Insertable<TasksTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? purpose,
    Expression<String>? iconId,
    Expression<int>? colorArgb,
    Expression<String>? graphicImage,
    Expression<String>? tagsJson,
    Expression<int>? startMinutes,
    Expression<int>? durationMinutes,
    Expression<String>? recurrenceType,
    Expression<String>? recurrenceRule,
    Expression<int>? repeatIntervalMinutes,
    Expression<bool>? notificationEnabled,
    Expression<int>? notificationOffsetMinutes,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? parentTaskId,
    Expression<String>? goalId,
    Expression<String>? taskDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (purpose != null) 'purpose': purpose,
      if (iconId != null) 'icon_id': iconId,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (graphicImage != null) 'graphic_image': graphicImage,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (repeatIntervalMinutes != null)
        'repeat_interval_minutes': repeatIntervalMinutes,
      if (notificationEnabled != null)
        'notification_enabled': notificationEnabled,
      if (notificationOffsetMinutes != null)
        'notification_offset_minutes': notificationOffsetMinutes,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (goalId != null) 'goal_id': goalId,
      if (taskDate != null) 'task_date': taskDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? purpose,
    Value<String?>? iconId,
    Value<int?>? colorArgb,
    Value<String?>? graphicImage,
    Value<String>? tagsJson,
    Value<int?>? startMinutes,
    Value<int?>? durationMinutes,
    Value<String>? recurrenceType,
    Value<String?>? recurrenceRule,
    Value<int?>? repeatIntervalMinutes,
    Value<bool>? notificationEnabled,
    Value<int>? notificationOffsetMinutes,
    Value<String>? status,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? parentTaskId,
    Value<String?>? goalId,
    Value<String>? taskDate,
    Value<int>? rowid,
  }) {
    return TasksTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      iconId: iconId ?? this.iconId,
      colorArgb: colorArgb ?? this.colorArgb,
      graphicImage: graphicImage ?? this.graphicImage,
      tagsJson: tagsJson ?? this.tagsJson,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationOffsetMinutes:
          notificationOffsetMinutes ?? this.notificationOffsetMinutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      goalId: goalId ?? this.goalId,
      taskDate: taskDate ?? this.taskDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (iconId.present) {
      map['icon_id'] = Variable<String>(iconId.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (graphicImage.present) {
      map['graphic_image'] = Variable<String>(graphicImage.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (repeatIntervalMinutes.present) {
      map['repeat_interval_minutes'] = Variable<int>(
        repeatIntervalMinutes.value,
      );
    }
    if (notificationEnabled.present) {
      map['notification_enabled'] = Variable<bool>(notificationEnabled.value);
    }
    if (notificationOffsetMinutes.present) {
      map['notification_offset_minutes'] = Variable<int>(
        notificationOffsetMinutes.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (taskDate.present) {
      map['task_date'] = Variable<String>(taskDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('purpose: $purpose, ')
          ..write('iconId: $iconId, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('graphicImage: $graphicImage, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('repeatIntervalMinutes: $repeatIntervalMinutes, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('notificationOffsetMinutes: $notificationOffsetMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('goalId: $goalId, ')
          ..write('taskDate: $taskDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTableTable extends TagsTable
    with TableInfo<$TagsTableTable, TagsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorArgb, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $TagsTableTable createAlias(String alias) {
    return $TagsTableTable(attachedDatabase, alias);
  }
}

class TagsTableData extends DataClass implements Insertable<TagsTableData> {
  final String id;
  final String name;
  final int? colorArgb;
  final DateTime createdAt;
  const TagsTableData({
    required this.id,
    required this.name,
    this.colorArgb,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorArgb != null) {
      map['color_argb'] = Variable<int>(colorArgb);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsTableCompanion toCompanion(bool nullToAbsent) {
    return TagsTableCompanion(
      id: Value(id),
      name: Value(name),
      colorArgb:
          colorArgb == null && nullToAbsent
              ? const Value.absent()
              : Value(colorArgb),
      createdAt: Value(createdAt),
    );
  }

  factory TagsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorArgb: serializer.fromJson<int?>(json['colorArgb']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorArgb': serializer.toJson<int?>(colorArgb),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TagsTableData copyWith({
    String? id,
    String? name,
    Value<int?> colorArgb = const Value.absent(),
    DateTime? createdAt,
  }) => TagsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorArgb: colorArgb.present ? colorArgb.value : this.colorArgb,
    createdAt: createdAt ?? this.createdAt,
  );
  TagsTableData copyWithCompanion(TagsTableCompanion data) {
    return TagsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorArgb, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorArgb == this.colorArgb &&
          other.createdAt == this.createdAt);
}

class TagsTableCompanion extends UpdateCompanion<TagsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> colorArgb;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsTableCompanion.insert({
    required String id,
    required String name,
    this.colorArgb = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TagsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorArgb,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? colorArgb,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailySummariesTableTable extends DailySummariesTable
    with TableInfo<$DailySummariesTableTable, DailySummariesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySummariesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskDateMeta = const VerificationMeta(
    'taskDate',
  );
  @override
  late final GeneratedColumn<String> taskDate = GeneratedColumn<String>(
    'task_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalScheduledMeta = const VerificationMeta(
    'totalScheduled',
  );
  @override
  late final GeneratedColumn<int> totalScheduled = GeneratedColumn<int>(
    'total_scheduled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCompletedMeta = const VerificationMeta(
    'totalCompleted',
  );
  @override
  late final GeneratedColumn<int> totalCompleted = GeneratedColumn<int>(
    'total_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDurationPlannedMeta =
      const VerificationMeta('totalDurationPlanned');
  @override
  late final GeneratedColumn<int> totalDurationPlanned = GeneratedColumn<int>(
    'total_duration_planned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDurationCompletedMeta =
      const VerificationMeta('totalDurationCompleted');
  @override
  late final GeneratedColumn<int> totalDurationCompleted = GeneratedColumn<int>(
    'total_duration_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _productivityScoreMeta = const VerificationMeta(
    'productivityScore',
  );
  @override
  late final GeneratedColumn<double> productivityScore =
      GeneratedColumn<double>(
        'productivity_score',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tagBreakdownJsonMeta = const VerificationMeta(
    'tagBreakdownJson',
  );
  @override
  late final GeneratedColumn<String> tagBreakdownJson = GeneratedColumn<String>(
    'tag_breakdown_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskDate,
    totalScheduled,
    totalCompleted,
    totalDurationPlanned,
    totalDurationCompleted,
    productivityScore,
    tagBreakdownJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySummariesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_date')) {
      context.handle(
        _taskDateMeta,
        taskDate.isAcceptableOrUnknown(data['task_date']!, _taskDateMeta),
      );
    } else if (isInserting) {
      context.missing(_taskDateMeta);
    }
    if (data.containsKey('total_scheduled')) {
      context.handle(
        _totalScheduledMeta,
        totalScheduled.isAcceptableOrUnknown(
          data['total_scheduled']!,
          _totalScheduledMeta,
        ),
      );
    }
    if (data.containsKey('total_completed')) {
      context.handle(
        _totalCompletedMeta,
        totalCompleted.isAcceptableOrUnknown(
          data['total_completed']!,
          _totalCompletedMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_planned')) {
      context.handle(
        _totalDurationPlannedMeta,
        totalDurationPlanned.isAcceptableOrUnknown(
          data['total_duration_planned']!,
          _totalDurationPlannedMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_completed')) {
      context.handle(
        _totalDurationCompletedMeta,
        totalDurationCompleted.isAcceptableOrUnknown(
          data['total_duration_completed']!,
          _totalDurationCompletedMeta,
        ),
      );
    }
    if (data.containsKey('productivity_score')) {
      context.handle(
        _productivityScoreMeta,
        productivityScore.isAcceptableOrUnknown(
          data['productivity_score']!,
          _productivityScoreMeta,
        ),
      );
    }
    if (data.containsKey('tag_breakdown_json')) {
      context.handle(
        _tagBreakdownJsonMeta,
        tagBreakdownJson.isAcceptableOrUnknown(
          data['tag_breakdown_json']!,
          _tagBreakdownJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskDate};
  @override
  DailySummariesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySummariesTableData(
      taskDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}task_date'],
          )!,
      totalScheduled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_scheduled'],
          )!,
      totalCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_completed'],
          )!,
      totalDurationPlanned:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_duration_planned'],
          )!,
      totalDurationCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_duration_completed'],
          )!,
      productivityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}productivity_score'],
      ),
      tagBreakdownJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tag_breakdown_json'],
          )!,
    );
  }

  @override
  $DailySummariesTableTable createAlias(String alias) {
    return $DailySummariesTableTable(attachedDatabase, alias);
  }
}

class DailySummariesTableData extends DataClass
    implements Insertable<DailySummariesTableData> {
  final String taskDate;
  final int totalScheduled;
  final int totalCompleted;
  final int totalDurationPlanned;
  final int totalDurationCompleted;
  final double? productivityScore;
  final String tagBreakdownJson;
  const DailySummariesTableData({
    required this.taskDate,
    required this.totalScheduled,
    required this.totalCompleted,
    required this.totalDurationPlanned,
    required this.totalDurationCompleted,
    this.productivityScore,
    required this.tagBreakdownJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_date'] = Variable<String>(taskDate);
    map['total_scheduled'] = Variable<int>(totalScheduled);
    map['total_completed'] = Variable<int>(totalCompleted);
    map['total_duration_planned'] = Variable<int>(totalDurationPlanned);
    map['total_duration_completed'] = Variable<int>(totalDurationCompleted);
    if (!nullToAbsent || productivityScore != null) {
      map['productivity_score'] = Variable<double>(productivityScore);
    }
    map['tag_breakdown_json'] = Variable<String>(tagBreakdownJson);
    return map;
  }

  DailySummariesTableCompanion toCompanion(bool nullToAbsent) {
    return DailySummariesTableCompanion(
      taskDate: Value(taskDate),
      totalScheduled: Value(totalScheduled),
      totalCompleted: Value(totalCompleted),
      totalDurationPlanned: Value(totalDurationPlanned),
      totalDurationCompleted: Value(totalDurationCompleted),
      productivityScore:
          productivityScore == null && nullToAbsent
              ? const Value.absent()
              : Value(productivityScore),
      tagBreakdownJson: Value(tagBreakdownJson),
    );
  }

  factory DailySummariesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySummariesTableData(
      taskDate: serializer.fromJson<String>(json['taskDate']),
      totalScheduled: serializer.fromJson<int>(json['totalScheduled']),
      totalCompleted: serializer.fromJson<int>(json['totalCompleted']),
      totalDurationPlanned: serializer.fromJson<int>(
        json['totalDurationPlanned'],
      ),
      totalDurationCompleted: serializer.fromJson<int>(
        json['totalDurationCompleted'],
      ),
      productivityScore: serializer.fromJson<double?>(
        json['productivityScore'],
      ),
      tagBreakdownJson: serializer.fromJson<String>(json['tagBreakdownJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskDate': serializer.toJson<String>(taskDate),
      'totalScheduled': serializer.toJson<int>(totalScheduled),
      'totalCompleted': serializer.toJson<int>(totalCompleted),
      'totalDurationPlanned': serializer.toJson<int>(totalDurationPlanned),
      'totalDurationCompleted': serializer.toJson<int>(totalDurationCompleted),
      'productivityScore': serializer.toJson<double?>(productivityScore),
      'tagBreakdownJson': serializer.toJson<String>(tagBreakdownJson),
    };
  }

  DailySummariesTableData copyWith({
    String? taskDate,
    int? totalScheduled,
    int? totalCompleted,
    int? totalDurationPlanned,
    int? totalDurationCompleted,
    Value<double?> productivityScore = const Value.absent(),
    String? tagBreakdownJson,
  }) => DailySummariesTableData(
    taskDate: taskDate ?? this.taskDate,
    totalScheduled: totalScheduled ?? this.totalScheduled,
    totalCompleted: totalCompleted ?? this.totalCompleted,
    totalDurationPlanned: totalDurationPlanned ?? this.totalDurationPlanned,
    totalDurationCompleted:
        totalDurationCompleted ?? this.totalDurationCompleted,
    productivityScore:
        productivityScore.present
            ? productivityScore.value
            : this.productivityScore,
    tagBreakdownJson: tagBreakdownJson ?? this.tagBreakdownJson,
  );
  DailySummariesTableData copyWithCompanion(DailySummariesTableCompanion data) {
    return DailySummariesTableData(
      taskDate: data.taskDate.present ? data.taskDate.value : this.taskDate,
      totalScheduled:
          data.totalScheduled.present
              ? data.totalScheduled.value
              : this.totalScheduled,
      totalCompleted:
          data.totalCompleted.present
              ? data.totalCompleted.value
              : this.totalCompleted,
      totalDurationPlanned:
          data.totalDurationPlanned.present
              ? data.totalDurationPlanned.value
              : this.totalDurationPlanned,
      totalDurationCompleted:
          data.totalDurationCompleted.present
              ? data.totalDurationCompleted.value
              : this.totalDurationCompleted,
      productivityScore:
          data.productivityScore.present
              ? data.productivityScore.value
              : this.productivityScore,
      tagBreakdownJson:
          data.tagBreakdownJson.present
              ? data.tagBreakdownJson.value
              : this.tagBreakdownJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesTableData(')
          ..write('taskDate: $taskDate, ')
          ..write('totalScheduled: $totalScheduled, ')
          ..write('totalCompleted: $totalCompleted, ')
          ..write('totalDurationPlanned: $totalDurationPlanned, ')
          ..write('totalDurationCompleted: $totalDurationCompleted, ')
          ..write('productivityScore: $productivityScore, ')
          ..write('tagBreakdownJson: $tagBreakdownJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskDate,
    totalScheduled,
    totalCompleted,
    totalDurationPlanned,
    totalDurationCompleted,
    productivityScore,
    tagBreakdownJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummariesTableData &&
          other.taskDate == this.taskDate &&
          other.totalScheduled == this.totalScheduled &&
          other.totalCompleted == this.totalCompleted &&
          other.totalDurationPlanned == this.totalDurationPlanned &&
          other.totalDurationCompleted == this.totalDurationCompleted &&
          other.productivityScore == this.productivityScore &&
          other.tagBreakdownJson == this.tagBreakdownJson);
}

class DailySummariesTableCompanion
    extends UpdateCompanion<DailySummariesTableData> {
  final Value<String> taskDate;
  final Value<int> totalScheduled;
  final Value<int> totalCompleted;
  final Value<int> totalDurationPlanned;
  final Value<int> totalDurationCompleted;
  final Value<double?> productivityScore;
  final Value<String> tagBreakdownJson;
  final Value<int> rowid;
  const DailySummariesTableCompanion({
    this.taskDate = const Value.absent(),
    this.totalScheduled = const Value.absent(),
    this.totalCompleted = const Value.absent(),
    this.totalDurationPlanned = const Value.absent(),
    this.totalDurationCompleted = const Value.absent(),
    this.productivityScore = const Value.absent(),
    this.tagBreakdownJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesTableCompanion.insert({
    required String taskDate,
    this.totalScheduled = const Value.absent(),
    this.totalCompleted = const Value.absent(),
    this.totalDurationPlanned = const Value.absent(),
    this.totalDurationCompleted = const Value.absent(),
    this.productivityScore = const Value.absent(),
    this.tagBreakdownJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskDate = Value(taskDate);
  static Insertable<DailySummariesTableData> custom({
    Expression<String>? taskDate,
    Expression<int>? totalScheduled,
    Expression<int>? totalCompleted,
    Expression<int>? totalDurationPlanned,
    Expression<int>? totalDurationCompleted,
    Expression<double>? productivityScore,
    Expression<String>? tagBreakdownJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskDate != null) 'task_date': taskDate,
      if (totalScheduled != null) 'total_scheduled': totalScheduled,
      if (totalCompleted != null) 'total_completed': totalCompleted,
      if (totalDurationPlanned != null)
        'total_duration_planned': totalDurationPlanned,
      if (totalDurationCompleted != null)
        'total_duration_completed': totalDurationCompleted,
      if (productivityScore != null) 'productivity_score': productivityScore,
      if (tagBreakdownJson != null) 'tag_breakdown_json': tagBreakdownJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesTableCompanion copyWith({
    Value<String>? taskDate,
    Value<int>? totalScheduled,
    Value<int>? totalCompleted,
    Value<int>? totalDurationPlanned,
    Value<int>? totalDurationCompleted,
    Value<double?>? productivityScore,
    Value<String>? tagBreakdownJson,
    Value<int>? rowid,
  }) {
    return DailySummariesTableCompanion(
      taskDate: taskDate ?? this.taskDate,
      totalScheduled: totalScheduled ?? this.totalScheduled,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      totalDurationPlanned: totalDurationPlanned ?? this.totalDurationPlanned,
      totalDurationCompleted:
          totalDurationCompleted ?? this.totalDurationCompleted,
      productivityScore: productivityScore ?? this.productivityScore,
      tagBreakdownJson: tagBreakdownJson ?? this.tagBreakdownJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskDate.present) {
      map['task_date'] = Variable<String>(taskDate.value);
    }
    if (totalScheduled.present) {
      map['total_scheduled'] = Variable<int>(totalScheduled.value);
    }
    if (totalCompleted.present) {
      map['total_completed'] = Variable<int>(totalCompleted.value);
    }
    if (totalDurationPlanned.present) {
      map['total_duration_planned'] = Variable<int>(totalDurationPlanned.value);
    }
    if (totalDurationCompleted.present) {
      map['total_duration_completed'] = Variable<int>(
        totalDurationCompleted.value,
      );
    }
    if (productivityScore.present) {
      map['productivity_score'] = Variable<double>(productivityScore.value);
    }
    if (tagBreakdownJson.present) {
      map['tag_breakdown_json'] = Variable<String>(tagBreakdownJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesTableCompanion(')
          ..write('taskDate: $taskDate, ')
          ..write('totalScheduled: $totalScheduled, ')
          ..write('totalCompleted: $totalCompleted, ')
          ..write('totalDurationPlanned: $totalDurationPlanned, ')
          ..write('totalDurationCompleted: $totalDurationCompleted, ')
          ..write('productivityScore: $productivityScore, ')
          ..write('tagBreakdownJson: $tagBreakdownJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTableTable extends GoalsTable
    with TableInfo<$GoalsTableTable, GoalsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('project'),
  );
  static const VerificationMeta _durationHoursMeta = const VerificationMeta(
    'durationHours',
  );
  @override
  late final GeneratedColumn<int> durationHours = GeneratedColumn<int>(
    'duration_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    durationHours,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('duration_hours')) {
      context.handle(
        _durationHoursMeta,
        durationHours.isAcceptableOrUnknown(
          data['duration_hours']!,
          _durationHoursMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      durationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_hours'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $GoalsTableTable createAlias(String alias) {
    return $GoalsTableTable(attachedDatabase, alias);
  }
}

class GoalsTableData extends DataClass implements Insertable<GoalsTableData> {
  final String id;
  final String title;
  final String type;

  /// Duration of the goal in hours. Null means no set time.
  final int? durationHours;
  final DateTime createdAt;
  const GoalsTableData({
    required this.id,
    required this.title,
    required this.type,
    this.durationHours,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || durationHours != null) {
      map['duration_hours'] = Variable<int>(durationHours);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GoalsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalsTableCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      durationHours:
          durationHours == null && nullToAbsent
              ? const Value.absent()
              : Value(durationHours),
      createdAt: Value(createdAt),
    );
  }

  factory GoalsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      durationHours: serializer.fromJson<int?>(json['durationHours']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'durationHours': serializer.toJson<int?>(durationHours),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GoalsTableData copyWith({
    String? id,
    String? title,
    String? type,
    Value<int?> durationHours = const Value.absent(),
    DateTime? createdAt,
  }) => GoalsTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    durationHours:
        durationHours.present ? durationHours.value : this.durationHours,
    createdAt: createdAt ?? this.createdAt,
  );
  GoalsTableData copyWithCompanion(GoalsTableCompanion data) {
    return GoalsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      durationHours:
          data.durationHours.present
              ? data.durationHours.value
              : this.durationHours,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('durationHours: $durationHours, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, type, durationHours, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.durationHours == this.durationHours &&
          other.createdAt == this.createdAt);
}

class GoalsTableCompanion extends UpdateCompanion<GoalsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<int?> durationHours;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GoalsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.durationHours = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsTableCompanion.insert({
    required String id,
    required String title,
    this.type = const Value.absent(),
    this.durationHours = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<GoalsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? durationHours,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (durationHours != null) 'duration_hours': durationHours,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? type,
    Value<int?>? durationHours,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GoalsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      durationHours: durationHours ?? this.durationHours,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (durationHours.present) {
      map['duration_hours'] = Variable<int>(durationHours.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('durationHours: $durationHours, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTableTable tasksTable = $TasksTableTable(this);
  late final $TagsTableTable tagsTable = $TagsTableTable(this);
  late final $DailySummariesTableTable dailySummariesTable =
      $DailySummariesTableTable(this);
  late final $GoalsTableTable goalsTable = $GoalsTableTable(this);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final AnalyticsDao analyticsDao = AnalyticsDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasksTable,
    tagsTable,
    dailySummariesTable,
    goalsTable,
  ];
}

typedef $$TasksTableTableCreateCompanionBuilder =
    TasksTableCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      Value<String?> purpose,
      Value<String?> iconId,
      Value<int?> colorArgb,
      Value<String?> graphicImage,
      Value<String> tagsJson,
      Value<int?> startMinutes,
      Value<int?> durationMinutes,
      Value<String> recurrenceType,
      Value<String?> recurrenceRule,
      Value<int?> repeatIntervalMinutes,
      Value<bool> notificationEnabled,
      Value<int> notificationOffsetMinutes,
      Value<String> status,
      Value<DateTime?> completedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> parentTaskId,
      Value<String?> goalId,
      required String taskDate,
      Value<int> rowid,
    });
typedef $$TasksTableTableUpdateCompanionBuilder =
    TasksTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String?> purpose,
      Value<String?> iconId,
      Value<int?> colorArgb,
      Value<String?> graphicImage,
      Value<String> tagsJson,
      Value<int?> startMinutes,
      Value<int?> durationMinutes,
      Value<String> recurrenceType,
      Value<String?> recurrenceRule,
      Value<int?> repeatIntervalMinutes,
      Value<bool> notificationEnabled,
      Value<int> notificationOffsetMinutes,
      Value<String> status,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> parentTaskId,
      Value<String?> goalId,
      Value<String> taskDate,
      Value<int> rowid,
    });

class $$TasksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconId => $composableBuilder(
    column: $table.iconId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get graphicImage => $composableBuilder(
    column: $table.graphicImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationOffsetMinutes => $composableBuilder(
    column: $table.notificationOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconId => $composableBuilder(
    column: $table.iconId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get graphicImage => $composableBuilder(
    column: $table.graphicImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationOffsetMinutes => $composableBuilder(
    column: $table.notificationOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get iconId =>
      $composableBuilder(column: $table.iconId, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<String> get graphicImage => $composableBuilder(
    column: $table.graphicImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationOffsetMinutes => $composableBuilder(
    column: $table.notificationOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get taskDate =>
      $composableBuilder(column: $table.taskDate, builder: (column) => column);
}

class $$TasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTableTable,
          TasksTableData,
          $$TasksTableTableFilterComposer,
          $$TasksTableTableOrderingComposer,
          $$TasksTableTableAnnotationComposer,
          $$TasksTableTableCreateCompanionBuilder,
          $$TasksTableTableUpdateCompanionBuilder,
          (
            TasksTableData,
            BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
          ),
          TasksTableData,
          PrefetchHooks Function()
        > {
  $$TasksTableTableTableManager(_$AppDatabase db, $TasksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TasksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> purpose = const Value.absent(),
                Value<String?> iconId = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                Value<String?> graphicImage = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int?> startMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> repeatIntervalMinutes = const Value.absent(),
                Value<bool> notificationEnabled = const Value.absent(),
                Value<int> notificationOffsetMinutes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<String> taskDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion(
                id: id,
                title: title,
                description: description,
                purpose: purpose,
                iconId: iconId,
                colorArgb: colorArgb,
                graphicImage: graphicImage,
                tagsJson: tagsJson,
                startMinutes: startMinutes,
                durationMinutes: durationMinutes,
                recurrenceType: recurrenceType,
                recurrenceRule: recurrenceRule,
                repeatIntervalMinutes: repeatIntervalMinutes,
                notificationEnabled: notificationEnabled,
                notificationOffsetMinutes: notificationOffsetMinutes,
                status: status,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                parentTaskId: parentTaskId,
                goalId: goalId,
                taskDate: taskDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> purpose = const Value.absent(),
                Value<String?> iconId = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                Value<String?> graphicImage = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int?> startMinutes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> repeatIntervalMinutes = const Value.absent(),
                Value<bool> notificationEnabled = const Value.absent(),
                Value<int> notificationOffsetMinutes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> parentTaskId = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                required String taskDate,
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                purpose: purpose,
                iconId: iconId,
                colorArgb: colorArgb,
                graphicImage: graphicImage,
                tagsJson: tagsJson,
                startMinutes: startMinutes,
                durationMinutes: durationMinutes,
                recurrenceType: recurrenceType,
                recurrenceRule: recurrenceRule,
                repeatIntervalMinutes: repeatIntervalMinutes,
                notificationEnabled: notificationEnabled,
                notificationOffsetMinutes: notificationOffsetMinutes,
                status: status,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                parentTaskId: parentTaskId,
                goalId: goalId,
                taskDate: taskDate,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTableTable,
      TasksTableData,
      $$TasksTableTableFilterComposer,
      $$TasksTableTableOrderingComposer,
      $$TasksTableTableAnnotationComposer,
      $$TasksTableTableCreateCompanionBuilder,
      $$TasksTableTableUpdateCompanionBuilder,
      (
        TasksTableData,
        BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
      ),
      TasksTableData,
      PrefetchHooks Function()
    >;
typedef $$TagsTableTableCreateCompanionBuilder =
    TagsTableCompanion Function({
      required String id,
      required String name,
      Value<int?> colorArgb,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TagsTableTableUpdateCompanionBuilder =
    TagsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> colorArgb,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TagsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTableTable,
          TagsTableData,
          $$TagsTableTableFilterComposer,
          $$TagsTableTableOrderingComposer,
          $$TagsTableTableAnnotationComposer,
          $$TagsTableTableCreateCompanionBuilder,
          $$TagsTableTableUpdateCompanionBuilder,
          (
            TagsTableData,
            BaseReferences<_$AppDatabase, $TagsTableTable, TagsTableData>,
          ),
          TagsTableData,
          PrefetchHooks Function()
        > {
  $$TagsTableTableTableManager(_$AppDatabase db, $TagsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TagsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> colorArgb = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion(
                id: id,
                name: name,
                colorArgb: colorArgb,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> colorArgb = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion.insert(
                id: id,
                name: name,
                colorArgb: colorArgb,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTableTable,
      TagsTableData,
      $$TagsTableTableFilterComposer,
      $$TagsTableTableOrderingComposer,
      $$TagsTableTableAnnotationComposer,
      $$TagsTableTableCreateCompanionBuilder,
      $$TagsTableTableUpdateCompanionBuilder,
      (
        TagsTableData,
        BaseReferences<_$AppDatabase, $TagsTableTable, TagsTableData>,
      ),
      TagsTableData,
      PrefetchHooks Function()
    >;
typedef $$DailySummariesTableTableCreateCompanionBuilder =
    DailySummariesTableCompanion Function({
      required String taskDate,
      Value<int> totalScheduled,
      Value<int> totalCompleted,
      Value<int> totalDurationPlanned,
      Value<int> totalDurationCompleted,
      Value<double?> productivityScore,
      Value<String> tagBreakdownJson,
      Value<int> rowid,
    });
typedef $$DailySummariesTableTableUpdateCompanionBuilder =
    DailySummariesTableCompanion Function({
      Value<String> taskDate,
      Value<int> totalScheduled,
      Value<int> totalCompleted,
      Value<int> totalDurationPlanned,
      Value<int> totalDurationCompleted,
      Value<double?> productivityScore,
      Value<String> tagBreakdownJson,
      Value<int> rowid,
    });

class $$DailySummariesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailySummariesTableTable> {
  $$DailySummariesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScheduled => $composableBuilder(
    column: $table.totalScheduled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCompleted => $composableBuilder(
    column: $table.totalCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationPlanned => $composableBuilder(
    column: $table.totalDurationPlanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationCompleted => $composableBuilder(
    column: $table.totalDurationCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get productivityScore => $composableBuilder(
    column: $table.productivityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagBreakdownJson => $composableBuilder(
    column: $table.tagBreakdownJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailySummariesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailySummariesTableTable> {
  $$DailySummariesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScheduled => $composableBuilder(
    column: $table.totalScheduled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCompleted => $composableBuilder(
    column: $table.totalCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationPlanned => $composableBuilder(
    column: $table.totalDurationPlanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationCompleted => $composableBuilder(
    column: $table.totalDurationCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get productivityScore => $composableBuilder(
    column: $table.productivityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagBreakdownJson => $composableBuilder(
    column: $table.tagBreakdownJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailySummariesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailySummariesTableTable> {
  $$DailySummariesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskDate =>
      $composableBuilder(column: $table.taskDate, builder: (column) => column);

  GeneratedColumn<int> get totalScheduled => $composableBuilder(
    column: $table.totalScheduled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCompleted => $composableBuilder(
    column: $table.totalCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationPlanned => $composableBuilder(
    column: $table.totalDurationPlanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationCompleted => $composableBuilder(
    column: $table.totalDurationCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<double> get productivityScore => $composableBuilder(
    column: $table.productivityScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagBreakdownJson => $composableBuilder(
    column: $table.tagBreakdownJson,
    builder: (column) => column,
  );
}

class $$DailySummariesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailySummariesTableTable,
          DailySummariesTableData,
          $$DailySummariesTableTableFilterComposer,
          $$DailySummariesTableTableOrderingComposer,
          $$DailySummariesTableTableAnnotationComposer,
          $$DailySummariesTableTableCreateCompanionBuilder,
          $$DailySummariesTableTableUpdateCompanionBuilder,
          (
            DailySummariesTableData,
            BaseReferences<
              _$AppDatabase,
              $DailySummariesTableTable,
              DailySummariesTableData
            >,
          ),
          DailySummariesTableData,
          PrefetchHooks Function()
        > {
  $$DailySummariesTableTableTableManager(
    _$AppDatabase db,
    $DailySummariesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DailySummariesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$DailySummariesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$DailySummariesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskDate = const Value.absent(),
                Value<int> totalScheduled = const Value.absent(),
                Value<int> totalCompleted = const Value.absent(),
                Value<int> totalDurationPlanned = const Value.absent(),
                Value<int> totalDurationCompleted = const Value.absent(),
                Value<double?> productivityScore = const Value.absent(),
                Value<String> tagBreakdownJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesTableCompanion(
                taskDate: taskDate,
                totalScheduled: totalScheduled,
                totalCompleted: totalCompleted,
                totalDurationPlanned: totalDurationPlanned,
                totalDurationCompleted: totalDurationCompleted,
                productivityScore: productivityScore,
                tagBreakdownJson: tagBreakdownJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskDate,
                Value<int> totalScheduled = const Value.absent(),
                Value<int> totalCompleted = const Value.absent(),
                Value<int> totalDurationPlanned = const Value.absent(),
                Value<int> totalDurationCompleted = const Value.absent(),
                Value<double?> productivityScore = const Value.absent(),
                Value<String> tagBreakdownJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesTableCompanion.insert(
                taskDate: taskDate,
                totalScheduled: totalScheduled,
                totalCompleted: totalCompleted,
                totalDurationPlanned: totalDurationPlanned,
                totalDurationCompleted: totalDurationCompleted,
                productivityScore: productivityScore,
                tagBreakdownJson: tagBreakdownJson,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailySummariesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailySummariesTableTable,
      DailySummariesTableData,
      $$DailySummariesTableTableFilterComposer,
      $$DailySummariesTableTableOrderingComposer,
      $$DailySummariesTableTableAnnotationComposer,
      $$DailySummariesTableTableCreateCompanionBuilder,
      $$DailySummariesTableTableUpdateCompanionBuilder,
      (
        DailySummariesTableData,
        BaseReferences<
          _$AppDatabase,
          $DailySummariesTableTable,
          DailySummariesTableData
        >,
      ),
      DailySummariesTableData,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableTableCreateCompanionBuilder =
    GoalsTableCompanion Function({
      required String id,
      required String title,
      Value<String> type,
      Value<int?> durationHours,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$GoalsTableTableUpdateCompanionBuilder =
    GoalsTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> type,
      Value<int?> durationHours,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$GoalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GoalsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTableTable,
          GoalsTableData,
          $$GoalsTableTableFilterComposer,
          $$GoalsTableTableOrderingComposer,
          $$GoalsTableTableAnnotationComposer,
          $$GoalsTableTableCreateCompanionBuilder,
          $$GoalsTableTableUpdateCompanionBuilder,
          (
            GoalsTableData,
            BaseReferences<_$AppDatabase, $GoalsTableTable, GoalsTableData>,
          ),
          GoalsTableData,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableTableManager(_$AppDatabase db, $GoalsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GoalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$GoalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$GoalsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> durationHours = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsTableCompanion(
                id: id,
                title: title,
                type: type,
                durationHours: durationHours,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> type = const Value.absent(),
                Value<int?> durationHours = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsTableCompanion.insert(
                id: id,
                title: title,
                type: type,
                durationHours: durationHours,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTableTable,
      GoalsTableData,
      $$GoalsTableTableFilterComposer,
      $$GoalsTableTableOrderingComposer,
      $$GoalsTableTableAnnotationComposer,
      $$GoalsTableTableCreateCompanionBuilder,
      $$GoalsTableTableUpdateCompanionBuilder,
      (
        GoalsTableData,
        BaseReferences<_$AppDatabase, $GoalsTableTable, GoalsTableData>,
      ),
      GoalsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db, _db.tasksTable);
  $$TagsTableTableTableManager get tagsTable =>
      $$TagsTableTableTableManager(_db, _db.tagsTable);
  $$DailySummariesTableTableTableManager get dailySummariesTable =>
      $$DailySummariesTableTableTableManager(_db, _db.dailySummariesTable);
  $$GoalsTableTableTableManager get goalsTable =>
      $$GoalsTableTableTableManager(_db, _db.goalsTable);
}
