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

  test('insertCapture 进收件箱、watchInbox 只出无排期的待办（新→旧）', () async {
    await db.taskDao.insertCapture(title: '第一条', domain: '学习');
    await db.taskDao.insertCapture(title: '第二条');
    // 一条直接给今天 → 不应出现在收件箱
    await db.taskDao
        .insertCapture(title: '今天就做', scheduledDate: d(8));

    final inbox = await db.taskDao.watchInbox().first;
    expect(inbox.map((t) => t.title), ['第二条', '第一条']); // id 倒序
    expect(inbox.first.source, TaskSource.capture);
    expect(inbox.last.domain, '学习');
  });

  test('addToToday 置今天日期 + 记 firstScheduledDate；setDomain 改标签', () async {
    final id = await db.taskDao.insertCapture(title: '收件箱里的');
    await db.taskDao.addToToday(id, d(8, 14)); // 带了时分，应只留日期
    var t = await db.taskDao.getById(id);
    expect(t!.scheduledDate, DateTime(2026, 6, 8));
    expect(t.firstScheduledDate, DateTime(2026, 6, 8));

    // 不再出现在收件箱
    final inbox = await db.taskDao.watchInbox().first;
    expect(inbox.where((x) => x.id == id), isEmpty);

    await db.taskDao.setDomain(id, '工作');
    t = await db.taskDao.getById(id);
    expect(t!.domain, '工作');

    await db.taskDao.setDomain(id, null);
    t = await db.taskDao.getById(id);
    expect(t!.domain, isNull);
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

  test('番茄列：incrementTomato 累加、setTomatoEst 设预估', () async {
    final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');
    var t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 0);
    expect(t.tomatoEst, isNull);

    await db.taskDao.setTomatoEst(id, 3);
    await db.taskDao.incrementTomato(id);
    await db.taskDao.incrementTomato(id);
    t = await db.taskDao.getById(id);
    expect(t!.tomatoEst, 3);
    expect(t.tomatoDone, 2);
  });

  test('捕获落 capture 事件、番茄落 tomato 事件', () async {
    final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');
    await db.taskDao.incrementTomato(id);

    final events = await db.taskEventDao.all();
    final types = events.map((e) => e.type).toList();
    expect(types, contains(TaskEventType.capture));
    expect(types, contains(TaskEventType.tomato));
  });
}
