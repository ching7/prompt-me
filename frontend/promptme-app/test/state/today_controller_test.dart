import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/integration_providers.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/today_controller.dart';

void main() {
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
            title: '项目周报',
            quadrant: Quadrant.importantUrgent,
          );
      final today = DateTime.now();
      final rows = await db.taskDao.tasksForDate(today);
      expect(rows.single.title, '项目周报');
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
          title: '完成项目周报',
          quadrant: Quadrant.importantUrgent,
          source: TaskSource.manual));
      final micro =
          await c.read(todayControllerProvider).tooHard(id, FailureReason.tired);
      expect(micro, contains('完成项目周报'));
      final row = await db.taskDao.getById(id);
      expect(row!.downgradeLevel, 1);
      expect(row.currentPromptText, micro);
      final ev = (await db.taskEventDao.forTask(id)).single;
      expect(ev.type, TaskEventType.tooHard);
      expect(ev.reason, FailureReason.tired);
    });

    test('AI 关闭时 tooHard 走本地兜底（即便有 key）', () async {
      SharedPreferences.setMockInitialValues(
          {'ai_key': 'sk-xxx', 'ai_enabled': false});
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c2.dispose);
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
          title: '完成项目周报',
          quadrant: Quadrant.importantUrgent,
          source: TaskSource.manual));
      final micro = await c2
          .read(todayControllerProvider)
          .tooHard(id, FailureReason.tired);
      expect(micro, contains('完成项目周报')); // 本地兜底文案，未发网络
    });
  });
}
