import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/todo/focus_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('显示任务名 + 倒计时；到点 +1🍅 转完成态', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
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
    final t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 1);
  });

  testWidgets('放弃 → 退出且不计数', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: 'A');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
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
    expect(t!.tomatoDone, 0);
  });
}
