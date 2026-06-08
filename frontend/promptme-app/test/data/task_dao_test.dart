import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DateTime d(int day, [int h = 0]) => DateTime(2026, 6, day, h);

  test('insert, fetch by date, mark done, completion days', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '项目周报',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
      scheduledDate: Value(d(3)),
    ));

    final todays = await db.taskDao.tasksForDate(d(3));
    expect(todays.single.title, '项目周报');

    await db.taskDao.markDone(id, d(3, 17));
    final done = await db.taskDao.getById(id);
    expect(done!.status, TaskStatus.done);

    final days = await db.taskDao.completionDays();
    expect(days, contains(DateTime(2026, 6, 3)));
  });

  test('applyDowngrade updates prompt + level', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '项目周报',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
    ));
    await db.taskDao.applyDowngrade(id, '只打开清单，写一句话', 1);
    final t = await db.taskDao.getById(id);
    expect(t!.currentPromptText, '只打开清单，写一句话');
    expect(t.downgradeLevel, 1);
  });

  test('domain 列可写可读、默认 null', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '研究 MCP 协议',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.capture,
      domain: Value('学习'),
    ));
    final t = await db.taskDao.getById(id);
    expect(t!.domain, '学习');

    final id2 = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '没打标签的',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.capture,
    ));
    final t2 = await db.taskDao.getById(id2);
    expect(t2!.domain, isNull);
  });
}
