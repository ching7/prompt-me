import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/todo/focus_screen.dart';
import 'package:promptme/services/ai/ai_client.dart';
import 'package:promptme/services/ai/ai_config.dart';
import 'package:promptme/state/integration_providers.dart';
import 'package:promptme/state/providers.dart';

/// 无 key 的 AI client → isActive=false（AI 估按钮不显，行为同改动前）。
final _aiOff = aiClientProvider
    .overrideWithValue(AiClient(config: const AiConfig(apiKey: '')));

void main() {
  testWidgets('显示任务名 + 倒计时；到点 +1🍅 转完成态', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), _aiOff],
      child: MaterialApp(
        home: FocusScreen(taskId: id, taskTitle: '写 Java 代码', workSeconds: 2),
      ),
    ));
    await tester.pump();
    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.text('00:02'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // → 0 → 完成
    await tester.pump(); // completeTomato 异步 + setState
    await tester.pumpAndSettle();

    expect(find.textContaining('完成'), findsOneWidget); // 完成态
    expect(find.textContaining('+10 分'), findsOneWidget); // 积分反馈
    final t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 1);
  });

  testWidgets('放弃 → 退出且不计数', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: 'A');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), _aiOff],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => FocusScreen(
                      taskId: id, taskTitle: 'A', workSeconds: 60))),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();

    expect(find.text('go'), findsOneWidget); // 已退回
    final t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 0); // 不计完成
    final events = await db.taskEventDao.forTask(id);
    expect(events.where((e) => e.type == TaskEventType.tomatoAbort).length, 1);
  });

  testWidgets('点预估「3」→ 任务 tomatoEst=3', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: 'A');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), _aiOff],
      child: MaterialApp(
        home: FocusScreen(taskId: id, taskTitle: 'A', workSeconds: 60),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('focus-est-3')));
    await tester.pump();
    expect((await db.taskDao.getById(id))!.tomatoEst, 3);
  });

  testWidgets('AI 开：出现「AI 估🍅」→ 点击落库估值', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '写周报');

    // 桩 AI：返回 "3" → 估 3 个番茄
    final http = MockClient((req) async => Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {'message': {'content': '3'}}
            ]
          })),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final aiOn = aiClientProvider.overrideWithValue(AiClient(
      config: const AiConfig(apiKey: 'k', enabled: true),
      client: http,
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), aiOn],
      child: MaterialApp(
        home: FocusScreen(taskId: id, taskTitle: '写周报', workSeconds: 60),
      ),
    ));
    await tester.pump();

    final btn = find.byKey(const ValueKey('focus-ai-est'));
    expect(btn, findsOneWidget); // AI 开 → 按钮出现
    await tester.tap(btn);
    await tester.pump(); // loading
    await tester.pump(const Duration(milliseconds: 50)); // 异步返回 + setState
    expect((await db.taskDao.getById(id))!.tomatoEst, 3);
  });
}
