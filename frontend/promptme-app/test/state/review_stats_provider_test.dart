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
    c.listen(reviewStatsProvider, (_, __) {}); // 保活，让 drift 流订阅并发射

    final stats = await c.read(reviewStatsProvider.future);
    expect(stats.todayDone, 1);
    expect(stats.todayTomato, 1);
    expect(stats.todayTooHard, 2);
    expect(stats.mapOverall.dominant, FailureReason.tired);
  });
}
