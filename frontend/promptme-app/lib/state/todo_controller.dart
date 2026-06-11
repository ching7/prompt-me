import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/ai/ai_models.dart';
import '../domain/enums.dart';
import '../domain/fogg/streak_calculator.dart';
import '../domain/score/score_calculator.dart';
import 'integration_providers.dart';
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

  /// 设番茄预估数（1–4）。
  Future<void> setTomatoEst(int id, int est) => _db.taskDao.setTomatoEst(id, est);

  /// 改任务标题（详情弹窗）。
  Future<void> editTitle(int id, String title) =>
      _db.taskDao.updateTitle(id, title);

  /// AI 估番茄：开 AI → 调模型估 1–4 并落库；关 AI → 返回 null（不估，保留手选现状）。
  Future<int?> estimateTomato(int id, String title) async {
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isActive) {
      debugPrint('[AI] 估🍅·未启用 → 跳过（保留手选）');
      return null;
    }
    debugPrint('[AI] 估🍅·调用（$title）');
    final n = await ai.estimateTomato(taskTitle: title);
    await setTomatoEst(id, n);
    debugPrint('[AI] 估🍅 → $n');
    return n;
  }

  /// 放弃番茄：记一条 tomatoAbort 事件（不计完成、不加分）。
  /// 带上**已专注秒数** [focusedSec] → 喂 MAP「二次诊断」（短放弃≈动机塌、半途≈能力塌）。
  Future<void> abortTomato(int id, {int? focusedSec}) => _db.taskEventDao.log(
        TaskEventsCompanion.insert(
          taskId: id,
          type: TaskEventType.tomatoAbort,
          createdAt: DateTime.now(),
          durationSec: Value(focusedSec),
        ),
      );

  /// AI 整理今日：收集今日待办标题 → prioritize（四象限 + 今日先做）。关 AI 返回 null。
  Future<PrioritizeResult?> prioritizeToday() async {
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isActive) {
      debugPrint('[AI] 整理·未启用 → 跳过');
      return null;
    }
    final today = ref.read(selectedDateProvider);
    final tasks = await _db.taskDao.tasksForDate(today);
    final titles = tasks
        .where((t) => t.status == TaskStatus.pending)
        .map((t) => t.title)
        .toList();
    debugPrint('[AI] 整理·调用 prioritize（${titles.length} 条待办）');
    final result = await ai.prioritize(taskTitles: titles, todayEvents: const []);
    debugPrint('[AI] 整理·返回 ${result.suggestions.length} 条建议');
    return result;
  }

  /// 即时算当前连续天数（庆祝弹层用，避免读到完成前的旧值）。
  Future<int> currentStreak() async {
    final days = await _db.taskDao.completionDays();
    return StreakCalculator.currentStreak(days, ref.read(selectedDateProvider));
  }

  /// 即时读总积分（庆祝「+N 分」后显示总分用，避免读旧值）。
  Future<int> currentPoints() async {
    final events = await _db.taskEventDao.all();
    return ScoreCalculator.total(events.map((e) => e.type));
  }
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
