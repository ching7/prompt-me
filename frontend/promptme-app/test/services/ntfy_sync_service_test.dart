import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/services/sync/ntfy_sync_service.dart';

String _line(Map<String, dynamic> payload) =>
    jsonEncode({'event': 'message', 'message': jsonEncode(payload)});

void main() {
  test('ntfy 同步：message 落库 + 幂等去重 + dest today；噪声忽略', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final controller = StreamController<String>();
    addTearDown(controller.close);
    final svc = NtfySyncService(db: db, connector: (_) => controller.stream);
    addTearDown(svc.stop);

    await svc.start('topic');

    controller.add(_line(
        {'v': 1, 'type': 'capture', 'id': 'x1', 'text': '收件想法', 'domain': '工作'}));
    controller.add(_line(
        {'v': 1, 'type': 'capture', 'id': 'x1', 'text': '收件想法'})); // 重复 id
    controller.add('{"event":"keepalive"}'); // 噪声
    controller.add('garbage'); // 非法
    controller.add(_line({
      'v': 1,
      'type': 'capture',
      'id': 'x2',
      'text': '今日想法',
      'dest': 'today'
    }));
    await pumpEventQueue();

    final inbox = await db.taskDao.watchInbox().first;
    expect(inbox.where((t) => t.title == '收件想法').length, 1); // 幂等：仅 1 条
    expect(inbox.first.domain, '工作');

    final today = await db.taskDao.tasksForDate(DateTime.now());
    expect(today.any((t) => t.title == '今日想法'), isTrue); // dest=today 进今日
  });

  test('insertSyncedCaptureIfNew 幂等：同 syncId 第二次返回 false', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final a =
        await db.taskDao.insertSyncedCaptureIfNew(syncId: 's1', title: 'A');
    final b =
        await db.taskDao.insertSyncedCaptureIfNew(syncId: 's1', title: 'A');
    expect(a, isTrue);
    expect(b, isFalse);
    final inbox = await db.taskDao.watchInbox().first;
    expect(inbox.where((t) => t.title == 'A').length, 1);
  });
}
