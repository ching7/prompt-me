import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/fogg/streak_calculator.dart';

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

final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  ref.watch(_todayTasksProvider); // 任务变化时重算
  final days = await db.taskDao.completionDays();
  return StreakCalculator.currentStreak(days, date);
});

// 仅监听今日任务表，替代旧 todayViewProvider 的刷新作用。
final _todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.taskDao.watchTasksForDate(date);
});
