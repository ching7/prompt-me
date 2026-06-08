import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/todo/todo_screen.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/todo_controller.dart';

void main() {
  testWidgets('渲染今日待办 + 已完成 + StatsChip + FAB', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.textContaining('今日待办'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('点勾选 → 移到已完成', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: 'A');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('todo-toggle')).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('已完成'), findsOneWidget);
  });

  testWidgets('右滑太难了 → 弹 sheet → 选原因 → 任务降级(标题变微习惯)', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    // 右滑(startToEnd)— fling 更可靠触发 Dismissible
    await tester.fling(find.text('写 Java 代码'), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('太难了？我帮你变小'), findsOneWidget); // sheet 出现

    await tester.tap(find.text('太累了'));
    await tester.pumpAndSettle();

    // 降级后原标题不再出现(被微习惯文案替代)
    expect(find.text('写 Java 代码'), findsNothing);
  });

  testWidgets('左滑我做到了 → 完成 + 庆祝,任务进已完成', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: 'A');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    // 左滑(endToStart)— fling 触发;庆祝有彩纸动画,用 pump(时长) 不用 pumpAndSettle(否则可能挂)
    await tester.fling(find.text('A'), const Offset(-400, 0), 1000);
    await tester.pump(); // 触发 confirmDismiss
    await tester.pump(const Duration(milliseconds: 600)); // 完成 + 庆祝弹出
    expect(find.textContaining('做到了'), findsOneWidget); // 庆祝层
    await tester.pump(const Duration(seconds: 2)); // CelebrationOverlay 1.9s 自动消失定时器
    await tester.pump(const Duration(milliseconds: 600));
    // 任务已进「已完成」
    expect(find.textContaining('已完成'), findsOneWidget);
  });
}
