import 'package:drift/drift.dart';
import '../database.dart';

part 'task_event_dao.g.dart';

@DriftAccessor(tables: [TaskEvents])
class TaskEventDao extends DatabaseAccessor<AppDatabase> with _$TaskEventDaoMixin {
  TaskEventDao(super.db);

  Future<int> log(TaskEventsCompanion event) => into(taskEvents).insert(event);

  Future<List<TaskEvent>> forTask(int taskId) =>
      (select(taskEvents)..where((e) => e.taskId.equals(taskId))).get();

  Future<List<TaskEvent>> all() => select(taskEvents).get();
}
