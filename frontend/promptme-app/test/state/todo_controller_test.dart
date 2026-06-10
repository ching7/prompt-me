import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/todo_controller.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  TodoController ctl() => container.read(todoControllerProvider);

  test('addToday 排今天 + 进 todoTodayProvider 的待办区', () async {
    container.listen(todoTodayProvider, (_, _) {});
    await ctl().addToday(text: '写 Java 代码', domain: '工作');
    final view = await container.read(todoTodayProvider.future);
    expect(view.pending.single.title, '写 Java 代码');
    expect(view.pending.single.domain, '工作');
    expect(view.doneCount, 0);
    expect(view.totalCount, 1);
  });

  test('complete 把任务移到已完成区', () async {
    container.listen(todoTodayProvider, (_, _) {});
    await ctl().addToday(text: 'A');
    final id = (await container.read(todoTodayProvider.future)).pending.single.id;
    await ctl().complete(id);
    // 直接从 DAO 读最新状态（一次性查询，不依赖流缓存）
    final task = await db.taskDao.getById(id);
    expect(task!.status, TaskStatus.done);
    // 验证今日任务聚合：watchTasksForDate 的最新 emission
    final rows = await db.taskDao.watchTasksForDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .first;
    final pending = rows.where((t) => t.status == TaskStatus.pending).toList();
    final done = rows.where((t) => t.status == TaskStatus.done).toList();
    expect(pending, isEmpty);
    expect(done.single.id, id);
    expect(done.length, 1);
    expect(pending.length + done.length, 1);
  });

  test('abortTomato 记 tomatoAbort 事件、不增 tomatoDone', () async {
    final id = await db.taskDao.insertCapture(title: '写周报');
    await ctl().abortTomato(id);
    final events = await db.taskEventDao.forTask(id);
    expect(events.where((e) => e.type == TaskEventType.tomatoAbort).length, 1);
    expect((await db.taskDao.getById(id))!.tomatoDone, 0);
  });

  test('setTomatoEst 写预估', () async {
    final id = await db.taskDao.insertCapture(title: '写周报');
    await ctl().setTomatoEst(id, 3);
    expect((await db.taskDao.getById(id))!.tomatoEst, 3);
  });
}
