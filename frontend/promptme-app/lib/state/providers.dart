import 'dart:async';
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

// 同时监听「任务表」和「日历事件表」：任一变化都重算今日视图。
// 仅 watch 任务表会漏掉「订阅拉取后写入日历事件」的刷新（订阅后不显示日程的根因）。
final todayViewProvider = StreamProvider.autoDispose<TodayView>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  final controller = StreamController<TodayView>();
  List<Task>? tasks;
  List<CalendarEvent>? events;
  void emit() {
    if (tasks == null || events == null) return;
    controller.add(TodayAggregator.build(
      events: events!.map(rowToTodayEvent).toList(),
      tasks: tasks!.map(rowToTodayTask).toList(),
    ));
  }

  final taskSub = db.taskDao.watchTasksForDate(date).listen((rows) {
    tasks = rows;
    emit();
  });
  final eventSub = db.calendarDao.watchEventsForDate(date).listen((rows) {
    events = rows;
    emit();
  });
  ref.onDispose(() {
    taskSub.cancel();
    eventSub.cancel();
    controller.close();
  });
  return controller.stream;
});

final subscriptionsProvider = StreamProvider.autoDispose<List<Subscription>>(
    (ref) => ref.watch(databaseProvider).calendarDao.watchSubscriptions());

final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(todayViewProvider); // 任务变化时重算
  final days = await db.taskDao.completionDays();
  return StreakCalculator.currentStreak(days, ref.read(selectedDateProvider));
});
