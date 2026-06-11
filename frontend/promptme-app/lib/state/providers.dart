import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/map_diagnosis.dart';
import '../domain/fogg/focus_diagnosis.dart';
import '../domain/fogg/streak_calculator.dart';
import '../domain/review/daily_trend.dart';
import '../domain/review/review_stats.dart';
import '../domain/score/score_calculator.dart';

DateTime _todayDate() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// MAP 诊断：显式「太难了」原因 + 番茄放弃时长推断的要素（二次喂诊断），一起喂入。
MapDiagnosis _diagnose(Iterable<TaskEvent> events) => MapDiagnosis.from(
      FocusDiagnosis.reasonsFrom(events.map(
          (e) => (type: e.type, reason: e.reason, durationSec: e.durationSec))),
    );

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// 始终为「今天」。Riverpod 3.x 移除了 StateProvider；这里只读不改，用普通 Provider。
final selectedDateProvider = Provider<DateTime>((_) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

// 流式：完成/重开任务即时重算，避免「第一次完成 streak 仍显示 0」。
final streakProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.taskDao
      .watchCompletionDays()
      .map((days) => StreakCalculator.currentStreak(days, date));
});

// 流式总积分：任意正向事件（捕获/完成/番茄）即时重算。
final pointsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.taskEventDao
      .watchAll()
      .map((events) => ScoreCalculator.total(events.map((e) => e.type)));
});

// 任务级 MAP 诊断：累积该任务历次「太难了」的失败要素 → 主因（纯派生）。
final taskDiagnosisProvider =
    StreamProvider.family<MapDiagnosis, int>((ref, taskId) {
  final db = ref.watch(databaseProvider);
  return db.taskEventDao.watchForTask(taskId).map(_diagnose);
});

// 复盘选中日期：默认今天，日历切换看历史某天。Riverpod 3.x 用 Notifier（无 StateProvider）。
class ReviewDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _todayDate();

  void set(DateTime d) => state = DateTime(d.year, d.month, d.day);

  /// 前后挪一天；不允许越过今天（未来无数据）。
  void shift(int days) {
    final n = state.add(Duration(days: days));
    final today = _todayDate();
    final clamped = DateTime(n.year, n.month, n.day);
    state = clamped.isAfter(today) ? today : clamped;
  }

  void toToday() => state = _todayDate();
}

final reviewDateProvider =
    NotifierProvider<ReviewDateNotifier, DateTime>(ReviewDateNotifier.new);

/// 复盘数据汇总（按给定日期）：当天完成/番茄/太难了 + 累计 MAP 主因（纯派生，响应式）。
final reviewStatsForDateProvider =
    StreamProvider.family<ReviewStats, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  bool sameDay(DateTime d) =>
      d.year == date.year && d.month == date.month && d.day == date.day;
  return db.taskEventDao.watchAll().map((events) {
    int ofType(TaskEventType t) =>
        events.where((e) => e.type == t && sameDay(e.createdAt)).length;
    // MAP 主因始终取「累计」（背景模式），不随选中日期变。含放弃时长二次喂诊断。
    final mapOverall = _diagnose(events);
    return ReviewStats(
      todayDone: ofType(TaskEventType.done),
      todayTomato: ofType(TaskEventType.tomato),
      todayTooHard: ofType(TaskEventType.tooHard),
      mapOverall: mapOverall,
    );
  });
});

// 复盘默认入口（今日）——保持向后兼容（既有测试/调用）。
final reviewStatsProvider = StreamProvider<ReviewStats>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(selectedDateProvider);
  bool isToday(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;
  return db.taskEventDao.watchAll().map((events) {
    int ofType(TaskEventType t) =>
        events.where((e) => e.type == t && isToday(e.createdAt)).length;
    final mapOverall = _diagnose(events);
    return ReviewStats(
      todayDone: ofType(TaskEventType.done),
      todayTomato: ofType(TaskEventType.tomato),
      todayTooHard: ofType(TaskEventType.tooHard),
      mapOverall: mapOverall,
    );
  });
});

/// 近 14 天趋势：每日积分/完成/番茄（旧→新，定长）。趋势曲线 + 历史导航用。
final dailyTrendProvider = StreamProvider<List<DayStat>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.taskEventDao.watchAll().map((events) => DailyTrend.lastNDays(
        events.map((e) => (type: e.type, at: e.createdAt)),
        _todayDate(),
        days: 14,
      ));
});
