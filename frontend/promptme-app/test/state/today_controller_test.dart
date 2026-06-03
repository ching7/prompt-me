import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/today_controller.dart';

void main() {
  test('rowToTodayTask shows micro prompt text after downgrade', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '农信问题',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.manual,
    ));
    var row = await db.taskDao.getById(id);
    expect(rowToTodayTask(row!).title, '农信问题');

    await db.taskDao.applyDowngrade(id, '只看一眼清单', 1);
    row = await db.taskDao.getById(id);
    expect(rowToTodayTask(row!).title, '只看一眼清单'); // 展示降级后的微版本
  });

  group('TodayController', () {
    late AppDatabase db;
    late ProviderContainer c;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    });
    tearDown(() {
      c.dispose();
      db.close();
    });

    test('addTask schedules for today with manual source', () async {
      await c.read(todayControllerProvider).addTask(
            title: '农信问题',
            quadrant: Quadrant.importantUrgent,
          );
      final today = DateTime.now();
      final rows = await db.taskDao.tasksForDate(today);
      expect(rows.single.title, '农信问题');
      expect(rows.single.source, TaskSource.manual);
    });

    test('complete marks done and logs a done event', () async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
          title: 'x', quadrant: Quadrant.importantUrgent, source: TaskSource.manual));
      await c.read(todayControllerProvider).complete(id);
      expect((await db.taskDao.getById(id))!.status, TaskStatus.done);
      expect((await db.taskEventDao.forTask(id)).single.type, TaskEventType.done);
    });

    test('tooHard shrinks, bumps level, logs reason', () async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
          title: '整理农信问题',
          quadrant: Quadrant.importantUrgent,
          source: TaskSource.manual));
      final micro =
          await c.read(todayControllerProvider).tooHard(id, FailureReason.tired);
      expect(micro, contains('整理农信问题'));
      final row = await db.taskDao.getById(id);
      expect(row!.downgradeLevel, 1);
      expect(row.currentPromptText, micro);
      final ev = (await db.taskEventDao.forTask(id)).single;
      expect(ev.type, TaskEventType.tooHard);
      expect(ev.reason, FailureReason.tired);
    });
  });
}
