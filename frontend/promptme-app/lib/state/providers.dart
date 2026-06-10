import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/map_diagnosis.dart';
import '../domain/fogg/streak_calculator.dart';
import '../domain/score/score_calculator.dart';

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
  return db.taskEventDao.watchForTask(taskId).map((events) => MapDiagnosis.from(
      events
          .where((e) => e.type == TaskEventType.tooHard && e.reason != null)
          .map((e) => e.reason!)));
});
