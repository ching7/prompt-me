// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [id, title, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String title;
  final String? notes;
  final DateTime createdAt;
  const Project({
    required this.id,
    required this.title,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Project copyWith({
    int? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => Project(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id)',
    ),
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<int> parentTaskId = GeneratedColumn<int>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Quadrant, int> quadrant =
      GeneratedColumn<int>(
        'quadrant',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Quadrant>($TasksTable.$converterquadrant);
  @override
  late final GeneratedColumnWithTypeConverter<TaskSource, int> source =
      GeneratedColumn<int>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskSource>($TasksTable.$convertersource);
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta(
    'estMinutes',
  );
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
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
  static const VerificationMeta _rolloverCountMeta = const VerificationMeta(
    'rolloverCount',
  );
  @override
  late final GeneratedColumn<int> rolloverCount = GeneratedColumn<int>(
    'rollover_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstScheduledDateMeta =
      const VerificationMeta('firstScheduledDate');
  @override
  late final GeneratedColumn<DateTime> firstScheduledDate =
      GeneratedColumn<DateTime>(
        'first_scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _currentPromptTextMeta = const VerificationMeta(
    'currentPromptText',
  );
  @override
  late final GeneratedColumn<String> currentPromptText =
      GeneratedColumn<String>(
        'current_prompt_text',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _downgradeLevelMeta = const VerificationMeta(
    'downgradeLevel',
  );
  @override
  late final GeneratedColumn<int> downgradeLevel = GeneratedColumn<int>(
    'downgrade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tomatoEstMeta = const VerificationMeta(
    'tomatoEst',
  );
  @override
  late final GeneratedColumn<int> tomatoEst = GeneratedColumn<int>(
    'tomato_est',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tomatoDoneMeta = const VerificationMeta(
    'tomatoDone',
  );
  @override
  late final GeneratedColumn<int> tomatoDone = GeneratedColumn<int>(
    'tomato_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    parentTaskId,
    title,
    quadrant,
    source,
    scheduledDate,
    estMinutes,
    status,
    completedAt,
    rolloverCount,
    firstScheduledDate,
    currentPromptText,
    downgradeLevel,
    domain,
    tomatoEst,
    tomatoDone,
    syncId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('est_minutes')) {
      context.handle(
        _estMinutesMeta,
        estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta),
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
    if (data.containsKey('rollover_count')) {
      context.handle(
        _rolloverCountMeta,
        rolloverCount.isAcceptableOrUnknown(
          data['rollover_count']!,
          _rolloverCountMeta,
        ),
      );
    }
    if (data.containsKey('first_scheduled_date')) {
      context.handle(
        _firstScheduledDateMeta,
        firstScheduledDate.isAcceptableOrUnknown(
          data['first_scheduled_date']!,
          _firstScheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('current_prompt_text')) {
      context.handle(
        _currentPromptTextMeta,
        currentPromptText.isAcceptableOrUnknown(
          data['current_prompt_text']!,
          _currentPromptTextMeta,
        ),
      );
    }
    if (data.containsKey('downgrade_level')) {
      context.handle(
        _downgradeLevelMeta,
        downgradeLevel.isAcceptableOrUnknown(
          data['downgrade_level']!,
          _downgradeLevelMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('tomato_est')) {
      context.handle(
        _tomatoEstMeta,
        tomatoEst.isAcceptableOrUnknown(data['tomato_est']!, _tomatoEstMeta),
      );
    }
    if (data.containsKey('tomato_done')) {
      context.handle(
        _tomatoDoneMeta,
        tomatoDone.isAcceptableOrUnknown(data['tomato_done']!, _tomatoDoneMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      ),
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_task_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      quadrant: $TasksTable.$converterquadrant.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}quadrant'],
        )!,
      ),
      source: $TasksTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}source'],
        )!,
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      estMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_minutes'],
      ),
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      rolloverCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rollover_count'],
      )!,
      firstScheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_scheduled_date'],
      ),
      currentPromptText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_prompt_text'],
      ),
      downgradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downgrade_level'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      tomatoEst: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tomato_est'],
      ),
      tomatoDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tomato_done'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Quadrant, int, int> $converterquadrant =
      const EnumIndexConverter<Quadrant>(Quadrant.values);
  static JsonTypeConverter2<TaskSource, int, int> $convertersource =
      const EnumIndexConverter<TaskSource>(TaskSource.values);
  static JsonTypeConverter2<TaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TaskStatus>(TaskStatus.values);
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final int? projectId;
  final int? parentTaskId;
  final String title;
  final Quadrant quadrant;
  final TaskSource source;
  final DateTime? scheduledDate;
  final int? estMinutes;
  final TaskStatus status;
  final DateTime? completedAt;
  final int rolloverCount;
  final DateTime? firstScheduledDate;
  final String? currentPromptText;
  final int downgradeLevel;
  final String? domain;
  final int? tomatoEst;
  final int tomatoDone;
  final String? syncId;
  const Task({
    required this.id,
    this.projectId,
    this.parentTaskId,
    required this.title,
    required this.quadrant,
    required this.source,
    this.scheduledDate,
    this.estMinutes,
    required this.status,
    this.completedAt,
    required this.rolloverCount,
    this.firstScheduledDate,
    this.currentPromptText,
    required this.downgradeLevel,
    this.domain,
    this.tomatoEst,
    required this.tomatoDone,
    this.syncId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<int>(parentTaskId);
    }
    map['title'] = Variable<String>(title);
    {
      map['quadrant'] = Variable<int>(
        $TasksTable.$converterquadrant.toSql(quadrant),
      );
    }
    {
      map['source'] = Variable<int>($TasksTable.$convertersource.toSql(source));
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || estMinutes != null) {
      map['est_minutes'] = Variable<int>(estMinutes);
    }
    {
      map['status'] = Variable<int>($TasksTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['rollover_count'] = Variable<int>(rolloverCount);
    if (!nullToAbsent || firstScheduledDate != null) {
      map['first_scheduled_date'] = Variable<DateTime>(firstScheduledDate);
    }
    if (!nullToAbsent || currentPromptText != null) {
      map['current_prompt_text'] = Variable<String>(currentPromptText);
    }
    map['downgrade_level'] = Variable<int>(downgradeLevel);
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    if (!nullToAbsent || tomatoEst != null) {
      map['tomato_est'] = Variable<int>(tomatoEst);
    }
    map['tomato_done'] = Variable<int>(tomatoDone);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      title: Value(title),
      quadrant: Value(quadrant),
      source: Value(source),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      estMinutes: estMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estMinutes),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      rolloverCount: Value(rolloverCount),
      firstScheduledDate: firstScheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(firstScheduledDate),
      currentPromptText: currentPromptText == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPromptText),
      downgradeLevel: Value(downgradeLevel),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      tomatoEst: tomatoEst == null && nullToAbsent
          ? const Value.absent()
          : Value(tomatoEst),
      tomatoDone: Value(tomatoDone),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      parentTaskId: serializer.fromJson<int?>(json['parentTaskId']),
      title: serializer.fromJson<String>(json['title']),
      quadrant: $TasksTable.$converterquadrant.fromJson(
        serializer.fromJson<int>(json['quadrant']),
      ),
      source: $TasksTable.$convertersource.fromJson(
        serializer.fromJson<int>(json['source']),
      ),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      estMinutes: serializer.fromJson<int?>(json['estMinutes']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      rolloverCount: serializer.fromJson<int>(json['rolloverCount']),
      firstScheduledDate: serializer.fromJson<DateTime?>(
        json['firstScheduledDate'],
      ),
      currentPromptText: serializer.fromJson<String?>(
        json['currentPromptText'],
      ),
      downgradeLevel: serializer.fromJson<int>(json['downgradeLevel']),
      domain: serializer.fromJson<String?>(json['domain']),
      tomatoEst: serializer.fromJson<int?>(json['tomatoEst']),
      tomatoDone: serializer.fromJson<int>(json['tomatoDone']),
      syncId: serializer.fromJson<String?>(json['syncId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int?>(projectId),
      'parentTaskId': serializer.toJson<int?>(parentTaskId),
      'title': serializer.toJson<String>(title),
      'quadrant': serializer.toJson<int>(
        $TasksTable.$converterquadrant.toJson(quadrant),
      ),
      'source': serializer.toJson<int>(
        $TasksTable.$convertersource.toJson(source),
      ),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'estMinutes': serializer.toJson<int?>(estMinutes),
      'status': serializer.toJson<int>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'rolloverCount': serializer.toJson<int>(rolloverCount),
      'firstScheduledDate': serializer.toJson<DateTime?>(firstScheduledDate),
      'currentPromptText': serializer.toJson<String?>(currentPromptText),
      'downgradeLevel': serializer.toJson<int>(downgradeLevel),
      'domain': serializer.toJson<String?>(domain),
      'tomatoEst': serializer.toJson<int?>(tomatoEst),
      'tomatoDone': serializer.toJson<int>(tomatoDone),
      'syncId': serializer.toJson<String?>(syncId),
    };
  }

  Task copyWith({
    int? id,
    Value<int?> projectId = const Value.absent(),
    Value<int?> parentTaskId = const Value.absent(),
    String? title,
    Quadrant? quadrant,
    TaskSource? source,
    Value<DateTime?> scheduledDate = const Value.absent(),
    Value<int?> estMinutes = const Value.absent(),
    TaskStatus? status,
    Value<DateTime?> completedAt = const Value.absent(),
    int? rolloverCount,
    Value<DateTime?> firstScheduledDate = const Value.absent(),
    Value<String?> currentPromptText = const Value.absent(),
    int? downgradeLevel,
    Value<String?> domain = const Value.absent(),
    Value<int?> tomatoEst = const Value.absent(),
    int? tomatoDone,
    Value<String?> syncId = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    title: title ?? this.title,
    quadrant: quadrant ?? this.quadrant,
    source: source ?? this.source,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    estMinutes: estMinutes.present ? estMinutes.value : this.estMinutes,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    rolloverCount: rolloverCount ?? this.rolloverCount,
    firstScheduledDate: firstScheduledDate.present
        ? firstScheduledDate.value
        : this.firstScheduledDate,
    currentPromptText: currentPromptText.present
        ? currentPromptText.value
        : this.currentPromptText,
    downgradeLevel: downgradeLevel ?? this.downgradeLevel,
    domain: domain.present ? domain.value : this.domain,
    tomatoEst: tomatoEst.present ? tomatoEst.value : this.tomatoEst,
    tomatoDone: tomatoDone ?? this.tomatoDone,
    syncId: syncId.present ? syncId.value : this.syncId,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      title: data.title.present ? data.title.value : this.title,
      quadrant: data.quadrant.present ? data.quadrant.value : this.quadrant,
      source: data.source.present ? data.source.value : this.source,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      estMinutes: data.estMinutes.present
          ? data.estMinutes.value
          : this.estMinutes,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      rolloverCount: data.rolloverCount.present
          ? data.rolloverCount.value
          : this.rolloverCount,
      firstScheduledDate: data.firstScheduledDate.present
          ? data.firstScheduledDate.value
          : this.firstScheduledDate,
      currentPromptText: data.currentPromptText.present
          ? data.currentPromptText.value
          : this.currentPromptText,
      downgradeLevel: data.downgradeLevel.present
          ? data.downgradeLevel.value
          : this.downgradeLevel,
      domain: data.domain.present ? data.domain.value : this.domain,
      tomatoEst: data.tomatoEst.present ? data.tomatoEst.value : this.tomatoEst,
      tomatoDone: data.tomatoDone.present
          ? data.tomatoDone.value
          : this.tomatoDone,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('title: $title, ')
          ..write('quadrant: $quadrant, ')
          ..write('source: $source, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('rolloverCount: $rolloverCount, ')
          ..write('firstScheduledDate: $firstScheduledDate, ')
          ..write('currentPromptText: $currentPromptText, ')
          ..write('downgradeLevel: $downgradeLevel, ')
          ..write('domain: $domain, ')
          ..write('tomatoEst: $tomatoEst, ')
          ..write('tomatoDone: $tomatoDone, ')
          ..write('syncId: $syncId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    parentTaskId,
    title,
    quadrant,
    source,
    scheduledDate,
    estMinutes,
    status,
    completedAt,
    rolloverCount,
    firstScheduledDate,
    currentPromptText,
    downgradeLevel,
    domain,
    tomatoEst,
    tomatoDone,
    syncId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.parentTaskId == this.parentTaskId &&
          other.title == this.title &&
          other.quadrant == this.quadrant &&
          other.source == this.source &&
          other.scheduledDate == this.scheduledDate &&
          other.estMinutes == this.estMinutes &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.rolloverCount == this.rolloverCount &&
          other.firstScheduledDate == this.firstScheduledDate &&
          other.currentPromptText == this.currentPromptText &&
          other.downgradeLevel == this.downgradeLevel &&
          other.domain == this.domain &&
          other.tomatoEst == this.tomatoEst &&
          other.tomatoDone == this.tomatoDone &&
          other.syncId == this.syncId);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<int?> projectId;
  final Value<int?> parentTaskId;
  final Value<String> title;
  final Value<Quadrant> quadrant;
  final Value<TaskSource> source;
  final Value<DateTime?> scheduledDate;
  final Value<int?> estMinutes;
  final Value<TaskStatus> status;
  final Value<DateTime?> completedAt;
  final Value<int> rolloverCount;
  final Value<DateTime?> firstScheduledDate;
  final Value<String?> currentPromptText;
  final Value<int> downgradeLevel;
  final Value<String?> domain;
  final Value<int?> tomatoEst;
  final Value<int> tomatoDone;
  final Value<String?> syncId;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.title = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.source = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rolloverCount = const Value.absent(),
    this.firstScheduledDate = const Value.absent(),
    this.currentPromptText = const Value.absent(),
    this.downgradeLevel = const Value.absent(),
    this.domain = const Value.absent(),
    this.tomatoEst = const Value.absent(),
    this.tomatoDone = const Value.absent(),
    this.syncId = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    required String title,
    required Quadrant quadrant,
    required TaskSource source,
    this.scheduledDate = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rolloverCount = const Value.absent(),
    this.firstScheduledDate = const Value.absent(),
    this.currentPromptText = const Value.absent(),
    this.downgradeLevel = const Value.absent(),
    this.domain = const Value.absent(),
    this.tomatoEst = const Value.absent(),
    this.tomatoDone = const Value.absent(),
    this.syncId = const Value.absent(),
  }) : title = Value(title),
       quadrant = Value(quadrant),
       source = Value(source);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? parentTaskId,
    Expression<String>? title,
    Expression<int>? quadrant,
    Expression<int>? source,
    Expression<DateTime>? scheduledDate,
    Expression<int>? estMinutes,
    Expression<int>? status,
    Expression<DateTime>? completedAt,
    Expression<int>? rolloverCount,
    Expression<DateTime>? firstScheduledDate,
    Expression<String>? currentPromptText,
    Expression<int>? downgradeLevel,
    Expression<String>? domain,
    Expression<int>? tomatoEst,
    Expression<int>? tomatoDone,
    Expression<String>? syncId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (title != null) 'title': title,
      if (quadrant != null) 'quadrant': quadrant,
      if (source != null) 'source': source,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (rolloverCount != null) 'rollover_count': rolloverCount,
      if (firstScheduledDate != null)
        'first_scheduled_date': firstScheduledDate,
      if (currentPromptText != null) 'current_prompt_text': currentPromptText,
      if (downgradeLevel != null) 'downgrade_level': downgradeLevel,
      if (domain != null) 'domain': domain,
      if (tomatoEst != null) 'tomato_est': tomatoEst,
      if (tomatoDone != null) 'tomato_done': tomatoDone,
      if (syncId != null) 'sync_id': syncId,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? projectId,
    Value<int?>? parentTaskId,
    Value<String>? title,
    Value<Quadrant>? quadrant,
    Value<TaskSource>? source,
    Value<DateTime?>? scheduledDate,
    Value<int?>? estMinutes,
    Value<TaskStatus>? status,
    Value<DateTime?>? completedAt,
    Value<int>? rolloverCount,
    Value<DateTime?>? firstScheduledDate,
    Value<String?>? currentPromptText,
    Value<int>? downgradeLevel,
    Value<String?>? domain,
    Value<int?>? tomatoEst,
    Value<int>? tomatoDone,
    Value<String?>? syncId,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      source: source ?? this.source,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estMinutes: estMinutes ?? this.estMinutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      rolloverCount: rolloverCount ?? this.rolloverCount,
      firstScheduledDate: firstScheduledDate ?? this.firstScheduledDate,
      currentPromptText: currentPromptText ?? this.currentPromptText,
      downgradeLevel: downgradeLevel ?? this.downgradeLevel,
      domain: domain ?? this.domain,
      tomatoEst: tomatoEst ?? this.tomatoEst,
      tomatoDone: tomatoDone ?? this.tomatoDone,
      syncId: syncId ?? this.syncId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<int>(parentTaskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (quadrant.present) {
      map['quadrant'] = Variable<int>(
        $TasksTable.$converterquadrant.toSql(quadrant.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<int>(
        $TasksTable.$convertersource.toSql(source.value),
      );
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rolloverCount.present) {
      map['rollover_count'] = Variable<int>(rolloverCount.value);
    }
    if (firstScheduledDate.present) {
      map['first_scheduled_date'] = Variable<DateTime>(
        firstScheduledDate.value,
      );
    }
    if (currentPromptText.present) {
      map['current_prompt_text'] = Variable<String>(currentPromptText.value);
    }
    if (downgradeLevel.present) {
      map['downgrade_level'] = Variable<int>(downgradeLevel.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (tomatoEst.present) {
      map['tomato_est'] = Variable<int>(tomatoEst.value);
    }
    if (tomatoDone.present) {
      map['tomato_done'] = Variable<int>(tomatoDone.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('title: $title, ')
          ..write('quadrant: $quadrant, ')
          ..write('source: $source, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('rolloverCount: $rolloverCount, ')
          ..write('firstScheduledDate: $firstScheduledDate, ')
          ..write('currentPromptText: $currentPromptText, ')
          ..write('downgradeLevel: $downgradeLevel, ')
          ..write('domain: $domain, ')
          ..write('tomatoEst: $tomatoEst, ')
          ..write('tomatoDone: $tomatoDone, ')
          ..write('syncId: $syncId')
          ..write(')'))
        .toString();
  }
}

class $TaskEventsTable extends TaskEvents
    with TableInfo<$TaskEventsTable, TaskEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskEventType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskEventType>($TaskEventsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<FailureReason?, int> reason =
      GeneratedColumn<int>(
        'reason',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<FailureReason?>($TaskEventsTable.$converterreasonn);
  static const VerificationMeta _microVersionTextMeta = const VerificationMeta(
    'microVersionText',
  );
  @override
  late final GeneratedColumn<String> microVersionText = GeneratedColumn<String>(
    'micro_version_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    type,
    reason,
    microVersionText,
    createdAt,
    durationSec,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('micro_version_text')) {
      context.handle(
        _microVersionTextMeta,
        microVersionText.isAcceptableOrUnknown(
          data['micro_version_text']!,
          _microVersionTextMeta,
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
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      type: $TaskEventsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      reason: $TaskEventsTable.$converterreasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reason'],
        ),
      ),
      microVersionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}micro_version_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
    );
  }

  @override
  $TaskEventsTable createAlias(String alias) {
    return $TaskEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskEventType, int, int> $convertertype =
      const EnumIndexConverter<TaskEventType>(TaskEventType.values);
  static JsonTypeConverter2<FailureReason, int, int> $converterreason =
      const EnumIndexConverter<FailureReason>(FailureReason.values);
  static JsonTypeConverter2<FailureReason?, int?, int?> $converterreasonn =
      JsonTypeConverter2.asNullable($converterreason);
}

class TaskEvent extends DataClass implements Insertable<TaskEvent> {
  final int id;
  final int taskId;
  final TaskEventType type;
  final FailureReason? reason;
  final String? microVersionText;
  final DateTime createdAt;
  final int? durationSec;
  const TaskEvent({
    required this.id,
    required this.taskId,
    required this.type,
    this.reason,
    this.microVersionText,
    required this.createdAt,
    this.durationSec,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    {
      map['type'] = Variable<int>($TaskEventsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<int>(
        $TaskEventsTable.$converterreasonn.toSql(reason),
      );
    }
    if (!nullToAbsent || microVersionText != null) {
      map['micro_version_text'] = Variable<String>(microVersionText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    return map;
  }

  TaskEventsCompanion toCompanion(bool nullToAbsent) {
    return TaskEventsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      type: Value(type),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      microVersionText: microVersionText == null && nullToAbsent
          ? const Value.absent()
          : Value(microVersionText),
      createdAt: Value(createdAt),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
    );
  }

  factory TaskEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEvent(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      type: $TaskEventsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      reason: $TaskEventsTable.$converterreasonn.fromJson(
        serializer.fromJson<int?>(json['reason']),
      ),
      microVersionText: serializer.fromJson<String?>(json['microVersionText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'type': serializer.toJson<int>(
        $TaskEventsTable.$convertertype.toJson(type),
      ),
      'reason': serializer.toJson<int?>(
        $TaskEventsTable.$converterreasonn.toJson(reason),
      ),
      'microVersionText': serializer.toJson<String?>(microVersionText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'durationSec': serializer.toJson<int?>(durationSec),
    };
  }

  TaskEvent copyWith({
    int? id,
    int? taskId,
    TaskEventType? type,
    Value<FailureReason?> reason = const Value.absent(),
    Value<String?> microVersionText = const Value.absent(),
    DateTime? createdAt,
    Value<int?> durationSec = const Value.absent(),
  }) => TaskEvent(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    type: type ?? this.type,
    reason: reason.present ? reason.value : this.reason,
    microVersionText: microVersionText.present
        ? microVersionText.value
        : this.microVersionText,
    createdAt: createdAt ?? this.createdAt,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
  );
  TaskEvent copyWithCompanion(TaskEventsCompanion data) {
    return TaskEvent(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      type: data.type.present ? data.type.value : this.type,
      reason: data.reason.present ? data.reason.value : this.reason,
      microVersionText: data.microVersionText.present
          ? data.microVersionText.value
          : this.microVersionText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEvent(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('microVersionText: $microVersionText, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSec: $durationSec')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    type,
    reason,
    microVersionText,
    createdAt,
    durationSec,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEvent &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.type == this.type &&
          other.reason == this.reason &&
          other.microVersionText == this.microVersionText &&
          other.createdAt == this.createdAt &&
          other.durationSec == this.durationSec);
}

class TaskEventsCompanion extends UpdateCompanion<TaskEvent> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<TaskEventType> type;
  final Value<FailureReason?> reason;
  final Value<String?> microVersionText;
  final Value<DateTime> createdAt;
  final Value<int?> durationSec;
  const TaskEventsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.type = const Value.absent(),
    this.reason = const Value.absent(),
    this.microVersionText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.durationSec = const Value.absent(),
  });
  TaskEventsCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required TaskEventType type,
    this.reason = const Value.absent(),
    this.microVersionText = const Value.absent(),
    required DateTime createdAt,
    this.durationSec = const Value.absent(),
  }) : taskId = Value(taskId),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<TaskEvent> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? type,
    Expression<int>? reason,
    Expression<String>? microVersionText,
    Expression<DateTime>? createdAt,
    Expression<int>? durationSec,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (type != null) 'type': type,
      if (reason != null) 'reason': reason,
      if (microVersionText != null) 'micro_version_text': microVersionText,
      if (createdAt != null) 'created_at': createdAt,
      if (durationSec != null) 'duration_sec': durationSec,
    });
  }

  TaskEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<TaskEventType>? type,
    Value<FailureReason?>? reason,
    Value<String?>? microVersionText,
    Value<DateTime>? createdAt,
    Value<int?>? durationSec,
  }) {
    return TaskEventsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      microVersionText: microVersionText ?? this.microVersionText,
      createdAt: createdAt ?? this.createdAt,
      durationSec: durationSec ?? this.durationSec,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $TaskEventsTable.$convertertype.toSql(type.value),
      );
    }
    if (reason.present) {
      map['reason'] = Variable<int>(
        $TaskEventsTable.$converterreasonn.toSql(reason.value),
      );
    }
    if (microVersionText.present) {
      map['micro_version_text'] = Variable<String>(microVersionText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskEventsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('microVersionText: $microVersionText, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSec: $durationSec')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, url, displayName, lastFetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final int id;
  final String url;
  final String displayName;
  final DateTime? lastFetchedAt;
  const Subscription({
    required this.id,
    required this.url,
    required this.displayName,
    this.lastFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url'] = Variable<String>(url);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      url: Value(url),
      displayName: Value(displayName),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      displayName: serializer.fromJson<String>(json['displayName']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'displayName': serializer.toJson<String>(displayName),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
    };
  }

  Subscription copyWith({
    int? id,
    String? url,
    String? displayName,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
  }) => Subscription(
    id: id ?? this.id,
    url: url ?? this.url,
    displayName: displayName ?? this.displayName,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('displayName: $displayName, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, url, displayName, lastFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.url == this.url &&
          other.displayName == this.displayName &&
          other.lastFetchedAt == this.lastFetchedAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<int> id;
  final Value<String> url;
  final Value<String> displayName;
  final Value<DateTime?> lastFetchedAt;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String url,
    required String displayName,
    this.lastFetchedAt = const Value.absent(),
  }) : url = Value(url),
       displayName = Value(displayName);
  static Insertable<Subscription> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? displayName,
    Expression<DateTime>? lastFetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (displayName != null) 'display_name': displayName,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? url,
    Value<String>? displayName,
    Value<DateTime?>? lastFetchedAt,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      displayName: displayName ?? this.displayName,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('displayName: $displayName, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subscriptionIdMeta = const VerificationMeta(
    'subscriptionId',
  );
  @override
  late final GeneratedColumn<int> subscriptionId = GeneratedColumn<int>(
    'subscription_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subscriptions (id)',
    ),
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _calendarNameMeta = const VerificationMeta(
    'calendarName',
  );
  @override
  late final GeneratedColumn<String> calendarName = GeneratedColumn<String>(
    'calendar_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subscriptionId,
    uid,
    title,
    start,
    end,
    allDay,
    calendarName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subscription_id')) {
      context.handle(
        _subscriptionIdMeta,
        subscriptionId.isAcceptableOrUnknown(
          data['subscription_id']!,
          _subscriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subscriptionIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('calendar_name')) {
      context.handle(
        _calendarNameMeta,
        calendarName.isAcceptableOrUnknown(
          data['calendar_name']!,
          _calendarNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subscription_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      calendarName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_name'],
      ),
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEvent extends DataClass implements Insertable<CalendarEvent> {
  final int id;
  final int subscriptionId;
  final String uid;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarName;
  const CalendarEvent({
    required this.id,
    required this.subscriptionId,
    required this.uid,
    required this.title,
    required this.start,
    this.end,
    required this.allDay,
    this.calendarName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subscription_id'] = Variable<int>(subscriptionId);
    map['uid'] = Variable<String>(uid);
    map['title'] = Variable<String>(title);
    map['start'] = Variable<DateTime>(start);
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<DateTime>(end);
    }
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || calendarName != null) {
      map['calendar_name'] = Variable<String>(calendarName);
    }
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      subscriptionId: Value(subscriptionId),
      uid: Value(uid),
      title: Value(title),
      start: Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
      allDay: Value(allDay),
      calendarName: calendarName == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarName),
    );
  }

  factory CalendarEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEvent(
      id: serializer.fromJson<int>(json['id']),
      subscriptionId: serializer.fromJson<int>(json['subscriptionId']),
      uid: serializer.fromJson<String>(json['uid']),
      title: serializer.fromJson<String>(json['title']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime?>(json['end']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      calendarName: serializer.fromJson<String?>(json['calendarName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subscriptionId': serializer.toJson<int>(subscriptionId),
      'uid': serializer.toJson<String>(uid),
      'title': serializer.toJson<String>(title),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime?>(end),
      'allDay': serializer.toJson<bool>(allDay),
      'calendarName': serializer.toJson<String?>(calendarName),
    };
  }

  CalendarEvent copyWith({
    int? id,
    int? subscriptionId,
    String? uid,
    String? title,
    DateTime? start,
    Value<DateTime?> end = const Value.absent(),
    bool? allDay,
    Value<String?> calendarName = const Value.absent(),
  }) => CalendarEvent(
    id: id ?? this.id,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    uid: uid ?? this.uid,
    title: title ?? this.title,
    start: start ?? this.start,
    end: end.present ? end.value : this.end,
    allDay: allDay ?? this.allDay,
    calendarName: calendarName.present ? calendarName.value : this.calendarName,
  );
  CalendarEvent copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEvent(
      id: data.id.present ? data.id.value : this.id,
      subscriptionId: data.subscriptionId.present
          ? data.subscriptionId.value
          : this.subscriptionId,
      uid: data.uid.present ? data.uid.value : this.uid,
      title: data.title.present ? data.title.value : this.title,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      calendarName: data.calendarName.present
          ? data.calendarName.value
          : this.calendarName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEvent(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('uid: $uid, ')
          ..write('title: $title, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('allDay: $allDay, ')
          ..write('calendarName: $calendarName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subscriptionId,
    uid,
    title,
    start,
    end,
    allDay,
    calendarName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEvent &&
          other.id == this.id &&
          other.subscriptionId == this.subscriptionId &&
          other.uid == this.uid &&
          other.title == this.title &&
          other.start == this.start &&
          other.end == this.end &&
          other.allDay == this.allDay &&
          other.calendarName == this.calendarName);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEvent> {
  final Value<int> id;
  final Value<int> subscriptionId;
  final Value<String> uid;
  final Value<String> title;
  final Value<DateTime> start;
  final Value<DateTime?> end;
  final Value<bool> allDay;
  final Value<String?> calendarName;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.subscriptionId = const Value.absent(),
    this.uid = const Value.absent(),
    this.title = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.allDay = const Value.absent(),
    this.calendarName = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    this.id = const Value.absent(),
    required int subscriptionId,
    required String uid,
    required String title,
    required DateTime start,
    this.end = const Value.absent(),
    this.allDay = const Value.absent(),
    this.calendarName = const Value.absent(),
  }) : subscriptionId = Value(subscriptionId),
       uid = Value(uid),
       title = Value(title),
       start = Value(start);
  static Insertable<CalendarEvent> custom({
    Expression<int>? id,
    Expression<int>? subscriptionId,
    Expression<String>? uid,
    Expression<String>? title,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<bool>? allDay,
    Expression<String>? calendarName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (uid != null) 'uid': uid,
      if (title != null) 'title': title,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (allDay != null) 'all_day': allDay,
      if (calendarName != null) 'calendar_name': calendarName,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? subscriptionId,
    Value<String>? uid,
    Value<String>? title,
    Value<DateTime>? start,
    Value<DateTime?>? end,
    Value<bool>? allDay,
    Value<String?>? calendarName,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      allDay: allDay ?? this.allDay,
      calendarName: calendarName ?? this.calendarName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subscriptionId.present) {
      map['subscription_id'] = Variable<int>(subscriptionId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (calendarName.present) {
      map['calendar_name'] = Variable<String>(calendarName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('uid: $uid, ')
          ..write('title: $title, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('allDay: $allDay, ')
          ..write('calendarName: $calendarName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskEventsTable taskEvents = $TaskEventsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final TaskEventDao taskEventDao = TaskEventDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    tasks,
    taskEvents,
    subscriptions,
    calendarEvents,
  ];
}

typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> notes,
      required DateTime createdAt,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(db.projects.id, db.tasks.projectId),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                title: title,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
              }) => ProjectsCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Task>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> projectId,
      Value<int?> parentTaskId,
      required String title,
      required Quadrant quadrant,
      required TaskSource source,
      Value<DateTime?> scheduledDate,
      Value<int?> estMinutes,
      Value<TaskStatus> status,
      Value<DateTime?> completedAt,
      Value<int> rolloverCount,
      Value<DateTime?> firstScheduledDate,
      Value<String?> currentPromptText,
      Value<int> downgradeLevel,
      Value<String?> domain,
      Value<int?> tomatoEst,
      Value<int> tomatoDone,
      Value<String?> syncId,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> projectId,
      Value<int?> parentTaskId,
      Value<String> title,
      Value<Quadrant> quadrant,
      Value<TaskSource> source,
      Value<DateTime?> scheduledDate,
      Value<int?> estMinutes,
      Value<TaskStatus> status,
      Value<DateTime?> completedAt,
      Value<int> rolloverCount,
      Value<DateTime?> firstScheduledDate,
      Value<String?> currentPromptText,
      Value<int> downgradeLevel,
      Value<String?> domain,
      Value<int?> tomatoEst,
      Value<int> tomatoDone,
      Value<String?> syncId,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) => db.projects
      .createAlias($_aliasNameGenerator(db.tasks.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TaskEventsTable, List<TaskEvent>>
  _taskEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskEvents,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskEvents.taskId),
  );

  $$TaskEventsTableProcessedTableManager get taskEventsRefs {
    final manager = $$TaskEventsTableTableManager(
      $_db,
      $_db.taskEvents,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Quadrant, Quadrant, int> get quadrant =>
      $composableBuilder(
        column: $table.quadrant,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TaskSource, TaskSource, int> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rolloverCount => $composableBuilder(
    column: $table.rolloverCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstScheduledDate => $composableBuilder(
    column: $table.firstScheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentPromptText => $composableBuilder(
    column: $table.currentPromptText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downgradeLevel => $composableBuilder(
    column: $table.downgradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tomatoEst => $composableBuilder(
    column: $table.tomatoEst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tomatoDone => $composableBuilder(
    column: $table.tomatoDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskEventsRefs(
    Expression<bool> Function($$TaskEventsTableFilterComposer f) f,
  ) {
    final $$TaskEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEvents,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEventsTableFilterComposer(
            $db: $db,
            $table: $db.taskEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rolloverCount => $composableBuilder(
    column: $table.rolloverCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstScheduledDate => $composableBuilder(
    column: $table.firstScheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentPromptText => $composableBuilder(
    column: $table.currentPromptText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downgradeLevel => $composableBuilder(
    column: $table.downgradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tomatoEst => $composableBuilder(
    column: $table.tomatoEst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tomatoDone => $composableBuilder(
    column: $table.tomatoDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Quadrant, int> get quadrant =>
      $composableBuilder(column: $table.quadrant, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskSource, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rolloverCount => $composableBuilder(
    column: $table.rolloverCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstScheduledDate => $composableBuilder(
    column: $table.firstScheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentPromptText => $composableBuilder(
    column: $table.currentPromptText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downgradeLevel => $composableBuilder(
    column: $table.downgradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<int> get tomatoEst =>
      $composableBuilder(column: $table.tomatoEst, builder: (column) => column);

  GeneratedColumn<int> get tomatoDone => $composableBuilder(
    column: $table.tomatoDone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskEventsRefs<T extends Object>(
    Expression<T> Function($$TaskEventsTableAnnotationComposer a) f,
  ) {
    final $$TaskEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEvents,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool projectId, bool taskEventsRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<int?> parentTaskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<Quadrant> quadrant = const Value.absent(),
                Value<TaskSource> source = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rolloverCount = const Value.absent(),
                Value<DateTime?> firstScheduledDate = const Value.absent(),
                Value<String?> currentPromptText = const Value.absent(),
                Value<int> downgradeLevel = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<int?> tomatoEst = const Value.absent(),
                Value<int> tomatoDone = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                projectId: projectId,
                parentTaskId: parentTaskId,
                title: title,
                quadrant: quadrant,
                source: source,
                scheduledDate: scheduledDate,
                estMinutes: estMinutes,
                status: status,
                completedAt: completedAt,
                rolloverCount: rolloverCount,
                firstScheduledDate: firstScheduledDate,
                currentPromptText: currentPromptText,
                downgradeLevel: downgradeLevel,
                domain: domain,
                tomatoEst: tomatoEst,
                tomatoDone: tomatoDone,
                syncId: syncId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<int?> parentTaskId = const Value.absent(),
                required String title,
                required Quadrant quadrant,
                required TaskSource source,
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rolloverCount = const Value.absent(),
                Value<DateTime?> firstScheduledDate = const Value.absent(),
                Value<String?> currentPromptText = const Value.absent(),
                Value<int> downgradeLevel = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<int?> tomatoEst = const Value.absent(),
                Value<int> tomatoDone = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                projectId: projectId,
                parentTaskId: parentTaskId,
                title: title,
                quadrant: quadrant,
                source: source,
                scheduledDate: scheduledDate,
                estMinutes: estMinutes,
                status: status,
                completedAt: completedAt,
                rolloverCount: rolloverCount,
                firstScheduledDate: firstScheduledDate,
                currentPromptText: currentPromptText,
                downgradeLevel: downgradeLevel,
                domain: domain,
                tomatoEst: tomatoEst,
                tomatoDone: tomatoDone,
                syncId: syncId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, taskEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (taskEventsRefs) db.taskEvents],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$TasksTableReferences
                                    ._projectIdTable(db),
                                referencedColumn: $$TasksTableReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskEventsRefs)
                    await $_getPrefetchedData<Task, $TasksTable, TaskEvent>(
                      currentTable: table,
                      referencedTable: $$TasksTableReferences
                          ._taskEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TasksTableReferences(db, table, p0).taskEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.taskId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool projectId, bool taskEventsRefs})
    >;
typedef $$TaskEventsTableCreateCompanionBuilder =
    TaskEventsCompanion Function({
      Value<int> id,
      required int taskId,
      required TaskEventType type,
      Value<FailureReason?> reason,
      Value<String?> microVersionText,
      required DateTime createdAt,
      Value<int?> durationSec,
    });
typedef $$TaskEventsTableUpdateCompanionBuilder =
    TaskEventsCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<TaskEventType> type,
      Value<FailureReason?> reason,
      Value<String?> microVersionText,
      Value<DateTime> createdAt,
      Value<int?> durationSec,
    });

final class $$TaskEventsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskEventsTable, TaskEvent> {
  $$TaskEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskEvents.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskEventsTable> {
  $$TaskEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskEventType, TaskEventType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<FailureReason?, FailureReason, int>
  get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get microVersionText => $composableBuilder(
    column: $table.microVersionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskEventsTable> {
  $$TaskEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get microVersionText => $composableBuilder(
    column: $table.microVersionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskEventsTable> {
  $$TaskEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskEventType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FailureReason?, int> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get microVersionText => $composableBuilder(
    column: $table.microVersionText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskEventsTable,
          TaskEvent,
          $$TaskEventsTableFilterComposer,
          $$TaskEventsTableOrderingComposer,
          $$TaskEventsTableAnnotationComposer,
          $$TaskEventsTableCreateCompanionBuilder,
          $$TaskEventsTableUpdateCompanionBuilder,
          (TaskEvent, $$TaskEventsTableReferences),
          TaskEvent,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskEventsTableTableManager(_$AppDatabase db, $TaskEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<TaskEventType> type = const Value.absent(),
                Value<FailureReason?> reason = const Value.absent(),
                Value<String?> microVersionText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
              }) => TaskEventsCompanion(
                id: id,
                taskId: taskId,
                type: type,
                reason: reason,
                microVersionText: microVersionText,
                createdAt: createdAt,
                durationSec: durationSec,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required TaskEventType type,
                Value<FailureReason?> reason = const Value.absent(),
                Value<String?> microVersionText = const Value.absent(),
                required DateTime createdAt,
                Value<int?> durationSec = const Value.absent(),
              }) => TaskEventsCompanion.insert(
                id: id,
                taskId: taskId,
                type: type,
                reason: reason,
                microVersionText: microVersionText,
                createdAt: createdAt,
                durationSec: durationSec,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskEventsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskEventsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskEventsTable,
      TaskEvent,
      $$TaskEventsTableFilterComposer,
      $$TaskEventsTableOrderingComposer,
      $$TaskEventsTableAnnotationComposer,
      $$TaskEventsTableCreateCompanionBuilder,
      $$TaskEventsTableUpdateCompanionBuilder,
      (TaskEvent, $$TaskEventsTableReferences),
      TaskEvent,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String url,
      required String displayName,
      Value<DateTime?> lastFetchedAt,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> url,
      Value<String> displayName,
      Value<DateTime?> lastFetchedAt,
    });

final class $$SubscriptionsTableReferences
    extends BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription> {
  $$SubscriptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEvent>>
  _calendarEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendarEvents,
    aliasName: $_aliasNameGenerator(
      db.subscriptions.id,
      db.calendarEvents.subscriptionId,
    ),
  );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.subscriptionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.subscriptionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.subscriptionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (Subscription, $$SubscriptionsTableReferences),
          Subscription,
          PrefetchHooks Function({bool calendarEventsRefs})
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                url: url,
                displayName: displayName,
                lastFetchedAt: lastFetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String url,
                required String displayName,
                Value<DateTime?> lastFetchedAt = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                url: url,
                displayName: displayName,
                lastFetchedAt: lastFetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubscriptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (calendarEventsRefs) db.calendarEvents,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (calendarEventsRefs)
                    await $_getPrefetchedData<
                      Subscription,
                      $SubscriptionsTable,
                      CalendarEvent
                    >(
                      currentTable: table,
                      referencedTable: $$SubscriptionsTableReferences
                          ._calendarEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SubscriptionsTableReferences(
                            db,
                            table,
                            p0,
                          ).calendarEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.subscriptionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (Subscription, $$SubscriptionsTableReferences),
      Subscription,
      PrefetchHooks Function({bool calendarEventsRefs})
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<int> id,
      required int subscriptionId,
      required String uid,
      required String title,
      required DateTime start,
      Value<DateTime?> end,
      Value<bool> allDay,
      Value<String?> calendarName,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<int> id,
      Value<int> subscriptionId,
      Value<String> uid,
      Value<String> title,
      Value<DateTime> start,
      Value<DateTime?> end,
      Value<bool> allDay,
      Value<String?> calendarName,
    });

final class $$CalendarEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent> {
  $$CalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SubscriptionsTable _subscriptionIdTable(_$AppDatabase db) =>
      db.subscriptions.createAlias(
        $_aliasNameGenerator(
          db.calendarEvents.subscriptionId,
          db.subscriptions.id,
        ),
      );

  $$SubscriptionsTableProcessedTableManager get subscriptionId {
    final $_column = $_itemColumn<int>('subscription_id')!;

    final manager = $$SubscriptionsTableTableManager(
      $_db,
      $_db.subscriptions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subscriptionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarName => $composableBuilder(
    column: $table.calendarName,
    builder: (column) => ColumnFilters(column),
  );

  $$SubscriptionsTableFilterComposer get subscriptionId {
    final $$SubscriptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableFilterComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarName => $composableBuilder(
    column: $table.calendarName,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubscriptionsTableOrderingComposer get subscriptionId {
    final $$SubscriptionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableOrderingComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get calendarName => $composableBuilder(
    column: $table.calendarName,
    builder: (column) => column,
  );

  $$SubscriptionsTableAnnotationComposer get subscriptionId {
    final $$SubscriptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEvent,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (CalendarEvent, $$CalendarEventsTableReferences),
          CalendarEvent,
          PrefetchHooks Function({bool subscriptionId})
        > {
  $$CalendarEventsTableTableManager(
    _$AppDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subscriptionId = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime?> end = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String?> calendarName = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                subscriptionId: subscriptionId,
                uid: uid,
                title: title,
                start: start,
                end: end,
                allDay: allDay,
                calendarName: calendarName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subscriptionId,
                required String uid,
                required String title,
                required DateTime start,
                Value<DateTime?> end = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String?> calendarName = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                subscriptionId: subscriptionId,
                uid: uid,
                title: title,
                start: start,
                end: end,
                allDay: allDay,
                calendarName: calendarName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subscriptionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subscriptionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subscriptionId,
                                referencedTable: $$CalendarEventsTableReferences
                                    ._subscriptionIdTable(db),
                                referencedColumn:
                                    $$CalendarEventsTableReferences
                                        ._subscriptionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEventsTable,
      CalendarEvent,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (CalendarEvent, $$CalendarEventsTableReferences),
      CalendarEvent,
      PrefetchHooks Function({bool subscriptionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskEventsTableTableManager get taskEvents =>
      $$TaskEventsTableTableManager(_db, _db.taskEvents);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
}
