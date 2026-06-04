import 'package:drift/drift.dart';
import '../database.dart';
import '../../domain/enums.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<Task?> getById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 某天的任务（按 scheduledDate 的日期部分匹配）。
  Future<List<Task>> tasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(start) &
              t.scheduledDate.isSmallerThanValue(end)))
        .get();
  }

  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(start) &
              t.scheduledDate.isSmallerThanValue(end)))
        .watch();
  }

  Future<void> markDone(int id, DateTime at) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        status: const Value(TaskStatus.done),
        completedAt: Value(at),
      ));

  /// 重新开启：状态回 pending、清掉完成时间（连续天数随之重算）。
  Future<void> reopen(int id) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(const TasksCompanion(
        status: Value(TaskStatus.pending),
        completedAt: Value<DateTime?>(null),
      ));

  Future<void> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> applyDowngrade(int id, String microText, int level) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        currentPromptText: Value(microText),
        downgradeLevel: Value(level),
      ));

  /// 所有已完成任务的「完成日期」集合（用于连续天数）。
  Future<Set<DateTime>> completionDays() async {
    final rows =
        await (select(tasks)..where((t) => t.completedAt.isNotNull())).get();
    return rows
        .map((r) => r.completedAt!)
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
  }
}
