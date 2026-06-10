import 'package:drift/drift.dart';
import '../database.dart';

part 'task_event_dao.g.dart';

@DriftAccessor(tables: [TaskEvents])
class TaskEventDao extends DatabaseAccessor<AppDatabase> with _$TaskEventDaoMixin {
  TaskEventDao(super.db);

  Future<int> log(TaskEventsCompanion event) => into(taskEvents).insert(event);

  Future<List<TaskEvent>> forTask(int taskId) =>
      (select(taskEvents)..where((e) => e.taskId.equals(taskId))).get();

  /// 某任务事件流（任务级 MAP 诊断响应式重算用）。
  Stream<List<TaskEvent>> watchForTask(int taskId) =>
      (select(taskEvents)..where((e) => e.taskId.equals(taskId))).watch();

  Future<void> deleteForTask(int taskId) =>
      (delete(taskEvents)..where((e) => e.taskId.equals(taskId))).go();

  Future<List<TaskEvent>> all() => select(taskEvents).get();

  /// 流：任意事件写入即推新（总积分响应式重算用）。
  Stream<List<TaskEvent>> watchAll() => select(taskEvents).watch();
}
