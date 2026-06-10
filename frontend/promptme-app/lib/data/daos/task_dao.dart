import 'package:drift/drift.dart';
import '../database.dart';
import '../../domain/enums.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  /// 捕获一条：source=capture，scheduledDate=null 进收件箱、=今天进待办。
  Future<int> insertCapture({
    required String title,
    String? domain,
    DateTime? scheduledDate,
  }) =>
      into(tasks).insert(TasksCompanion.insert(
        title: title,
        quadrant: Quadrant.importantUrgent, // 占位，UI 不用
        source: TaskSource.capture,
        domain: Value(domain),
        scheduledDate: Value(scheduledDate),
      ));

  /// 收件箱 = 无排期且待办，新→旧。
  Stream<List<Task>> watchInbox() => (select(tasks)
        ..where((t) =>
            t.scheduledDate.isNull() &
            t.status.equalsValue(TaskStatus.pending))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .watch();

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

  /// 加入今日：scheduledDate=今天（仅日期），首次排期记 firstScheduledDate。
  Future<void> addToToday(int id, DateTime today) async {
    final dateOnly = DateTime(today.year, today.month, today.day);
    final existing = await getById(id);
    await (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      scheduledDate: Value(dateOnly),
      firstScheduledDate: Value(existing?.firstScheduledDate ?? dateOnly),
    ));
  }

  /// 设/清领域标签。
  Future<void> setDomain(int id, String? domain) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(domain: Value(domain)));

  /// 完成一个番茄：tomatoDone += 1。
  Future<void> incrementTomato(int id) async {
    final t = await getById(id);
    await (update(tasks)..where((x) => x.id.equals(id)))
        .write(TasksCompanion(tomatoDone: Value((t?.tomatoDone ?? 0) + 1)));
  }

  /// 设番茄预估数。
  Future<void> setTomatoEst(int id, int est) =>
      (update(tasks)..where((x) => x.id.equals(id)))
          .write(TasksCompanion(tomatoEst: Value(est)));

  /// 所有已完成任务的「完成日期」集合（用于连续天数）。
  Future<Set<DateTime>> completionDays() async => _daysFrom(
      await (select(tasks)..where((t) => t.completedAt.isNotNull())).get());

  /// 同上，但作为流：完成/重开任务即时重算连续天数（修一次完成后 streak 滞后）。
  Stream<Set<DateTime>> watchCompletionDays() =>
      (select(tasks)..where((t) => t.completedAt.isNotNull()))
          .watch()
          .map(_daysFrom);

  Set<DateTime> _daysFrom(List<Task> rows) => rows
      .map((r) => r.completedAt!)
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();
}
