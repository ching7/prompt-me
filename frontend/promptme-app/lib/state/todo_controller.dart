import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import 'providers.dart';
import 'today_controller.dart';

/// 今日视图：待办(pending)+ 已完成(done)。
class TodoToday {
  TodoToday(this.pending, this.done);
  final List<Task> pending;
  final List<Task> done;
  int get doneCount => done.length;
  int get totalCount => pending.length + done.length;
}

class TodoController {
  TodoController(this.ref);
  final Ref ref;
  AppDatabase get _db => ref.read(databaseProvider);

  /// 直接加一条到今日(文本 + 可选领域)。
  Future<void> addToday({required String text, String? domain}) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return _db.taskDao.insertCapture(
        title: text, domain: domain, scheduledDate: today);
  }

  /// 完成 / 重开 / 删除 / 太难了：复用 TodayController（含事件记录）。
  Future<void> complete(int id) =>
      ref.read(todayControllerProvider).complete(id);
  Future<void> reopen(int id) =>
      ref.read(todayControllerProvider).reopen(id);
  Future<void> delete(int id) =>
      ref.read(todayControllerProvider).deleteTask(id);
  Future<void> tooHard(int id, FailureReason reason) =>
      ref.read(todayControllerProvider).tooHard(id, reason);

  /// 完成一个番茄（+1 🍅）。
  Future<void> completeTomato(int id) => _db.taskDao.incrementTomato(id);
}

final todoControllerProvider =
    Provider<TodoController>((ref) => TodoController(ref));

/// 今日任务流 → 分待办 / 已完成。
final todoTodayProvider = StreamProvider<TodoToday>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.taskDao.watchTasksForDate(date).map((rows) {
    final pending = rows.where((t) => t.status == TaskStatus.pending).toList();
    final done = rows.where((t) => t.status == TaskStatus.done).toList();
    return TodoToday(pending, done);
  });
});
