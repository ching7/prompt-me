import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/inbox/inbox_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('渲染收件箱条目 + 全部加入今日按钮 + FAB', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.taskDao.insertCapture(title: '研究 MCP 协议', domain: '学习');
    await db.taskDao.insertCapture(title: '给奶奶约复查');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: InboxScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('研究 MCP 协议'), findsOneWidget);
    expect(find.text('给奶奶约复查'), findsOneWidget);
    expect(find.textContaining('全部加入今日'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 关闭 DB 再 unmount，避免 Drift stream 定时器在 widget 拆卸后残留
    await db.close();
    await tester.pump();
  });

  testWidgets('点全部加入今日 → 列表清空', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.taskDao.insertCapture(title: 'A');
    await db.taskDao.insertCapture(title: 'B');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: InboxScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('全部加入今日'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    await db.close();
    await tester.pump();
  });
}
