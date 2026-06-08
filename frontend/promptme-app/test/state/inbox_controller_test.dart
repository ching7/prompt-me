import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/state/inbox_controller.dart';
import 'package:promptme/state/providers.dart';

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

  InboxController ctl() => container.read(inboxControllerProvider);

  /// 直接读 DAO 流的下一次 emission（不依赖 provider 缓存）。
  Future<List<Task>> nextInbox() => db.taskDao.watchInbox().first;

  test('capture 进收件箱（带领域），inboxProvider 流出', () async {
    await ctl().capture(text: '研究 MCP 协议', domain: '学习');
    await ctl().capture(text: '没标签的');
    // 验证 inboxProvider 能正确接入 DAO stream
    container.listen(inboxProvider, (_, __) {});
    final inbox = await container.read(inboxProvider.future);
    expect(inbox.map((t) => t.title), ['没标签的', '研究 MCP 协议']); // 新→旧
    expect(inbox.last.domain, '学习');
  });

  test('addToToday 把条目移出收件箱、置今天', () async {
    await ctl().capture(text: 'A');
    final id = (await nextInbox()).single.id;
    await ctl().addToToday(id);
    final t = await db.taskDao.getById(id);
    final n = DateTime.now();
    expect(t!.scheduledDate, DateTime(n.year, n.month, n.day));
    expect(await nextInbox(), isEmpty);
  });

  test('addAllToToday 批量清空收件箱', () async {
    await ctl().capture(text: 'A');
    await ctl().capture(text: 'B');
    final ids = (await nextInbox()).map((t) => t.id).toList();
    await ctl().addAllToToday(ids);
    expect(await nextInbox(), isEmpty);
  });

  test('delete 移除条目', () async {
    await ctl().capture(text: 'A');
    final id = (await nextInbox()).single.id;
    await ctl().delete(id);
    expect(await nextInbox(), isEmpty);
  });
}
