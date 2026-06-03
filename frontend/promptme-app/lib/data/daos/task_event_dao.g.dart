// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_event_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TaskEventsTable get taskEvents => attachedDatabase.taskEvents;
  TaskEventDaoManager get managers => TaskEventDaoManager(this);
}

class TaskEventDaoManager {
  final _$TaskEventDaoMixin _db;
  TaskEventDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TaskEventsTableTableManager get taskEvents =>
      $$TaskEventsTableTableManager(_db.attachedDatabase, _db.taskEvents);
}
