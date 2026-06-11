import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/providers.dart';

void main() {
  test('reviewStatsProvider 聚合今日完成/番茄/太难了 + 累计 MAP 主因', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // 先把事件全部写入：捕获(capture) + 完成(done) + 番茄(tomato) + 同因 tooHard×2
    final id = await db.taskDao.insertCapture(title: '写周报');
    await db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: id, type: TaskEventType.done, createdAt: DateTime.now()));
    await db.taskDao.incrementTomato(id); // tomato 事件
    for (var i = 0; i < 2; i++) {
      await db.taskEventDao.log(TaskEventsCompanion.insert(
          taskId: id,
          type: TaskEventType.tooHard,
          reason: const Value(FailureReason.tired),
          createdAt: DateTime.now()));
    }

    // 写完再读：流的首次发射即反映已写入的数据
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(reviewStatsProvider, (_, _) {}); // 保活，让 drift 流订阅并发射

    final stats = await c.read(reviewStatsProvider.future);
    expect(stats.todayDone, 1);
    expect(stats.todayTomato, 1);
    expect(stats.todayTooHard, 2);
    expect(stats.mapOverall.dominant, FailureReason.tired);
  });

  test('reviewStatsForDateProvider 按日期聚合：昨天=1、今天=0', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '昨天的事');
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    await db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: id, type: TaskEventType.done, createdAt: yesterday));

    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    final today = DateTime(now.year, now.month, now.day);
    c.listen(reviewStatsForDateProvider(yesterday), (_, _) {});
    c.listen(reviewStatsForDateProvider(today), (_, _) {});

    final y = await c.read(reviewStatsForDateProvider(yesterday).future);
    final t = await c.read(reviewStatsForDateProvider(today).future);
    expect(y.todayDone, 1); // 昨天完成 1
    expect(t.todayDone, 0); // 今天 0
  });

  test('dailyTrendProvider 近 14 天定长、昨天积分=10', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: 'x');
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 9));
    await db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: id, type: TaskEventType.done, createdAt: yesterday));

    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(dailyTrendProvider, (_, _) {});
    final trend = await c.read(dailyTrendProvider.future);
    expect(trend.length, 14);
    expect(trend[trend.length - 2].points, 10); // 倒数第二天=昨天(done +10)
    expect(trend.last.points, 2); // 今天=insertCapture 的 capture 事件 +2
  });

  test('reviewDateProvider notifier：shift 不越过今天 + toToday 回跳', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final today = c.read(reviewDateProvider);

    c.read(reviewDateProvider.notifier).shift(-1);
    expect(c.read(reviewDateProvider), today.subtract(const Duration(days: 1)));

    // 连点 +1 两次：最多回到今天，不越界
    c.read(reviewDateProvider.notifier).shift(1);
    c.read(reviewDateProvider.notifier).shift(1);
    expect(c.read(reviewDateProvider), today);

    c.read(reviewDateProvider.notifier).shift(-3);
    c.read(reviewDateProvider.notifier).toToday();
    expect(c.read(reviewDateProvider), today);
  });
}
