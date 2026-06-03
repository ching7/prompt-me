import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/streak_calculator.dart';
import '../domain/fogg/today_aggregator.dart';

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

TodayTask rowToTodayTask(Task row) => TodayTask(
      id: row.id,
      title: (row.currentPromptText?.isNotEmpty ?? false)
          ? row.currentPromptText!
          : row.title,
      quadrant: row.quadrant,
      done: row.status == TaskStatus.done,
    );

TodayEvent rowToTodayEvent(CalendarEvent e) => TodayEvent(
      title: e.title,
      start: e.start,
      end: e.end,
      allDay: e.allDay,
      calendarName: e.calendarName,
    );

final todayViewProvider = StreamProvider.autoDispose<TodayView>((ref) async* {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  await for (final taskRows in db.taskDao.watchTasksForDate(date)) {
    final eventRows = await db.calendarDao.eventsForDate(date);
    yield TodayAggregator.build(
      events: eventRows.map(rowToTodayEvent).toList(),
      tasks: taskRows.map(rowToTodayTask).toList(),
    );
  }
});

final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(todayViewProvider); // 任务变化时重算
  final days = await db.taskDao.completionDays();
  return StreakCalculator.currentStreak(days, ref.read(selectedDateProvider));
});
