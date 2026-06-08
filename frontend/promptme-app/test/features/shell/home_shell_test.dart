import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/shell/home_shell.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('三 Tab 默认在待办、收件箱有 FAB、可切到复盘', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();

    // 底部三个 Tab 标签都在
    expect(find.text('收件箱'), findsWidgets); // 导航标签（收件箱屏也有同名标题，故 findsWidgets）
    expect(find.text('待办'), findsWidgets);
    expect(find.text('复盘'), findsOneWidget);

    // 默认选中「待办」→ 待办占位屏标题可见
    expect(find.text('待办 · 占位'), findsOneWidget);

    // 切到收件箱 → 真实屏的 FAB 出现（占位屏没有 FAB）
    await tester.tap(find.text('收件箱').last);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 切到复盘
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('复盘 · 占位'), findsOneWidget);

    // 关闭 DB 再 unmount，避免 Drift stream 定时器在 widget 拆卸后残留
    await db.close();
    await tester.pump();
  });
}
