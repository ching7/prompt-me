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
}
