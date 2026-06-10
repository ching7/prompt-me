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

    // 默认选中「待办」→ 真实待办屏:今日待办区可见
    expect(find.textContaining('今日待办'), findsOneWidget);

    // 切到收件箱 → 真实屏的 FAB 出现（占位屏没有 FAB）
    await tester.tap(find.text('收件箱').last);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 切到复盘 → 真复盘屏（非占位）
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('今日小结'), findsOneWidget);

    // 关闭 DB 再 unmount，避免 Drift stream 定时器在 widget 拆卸后残留
    await db.close();
    await tester.pump();
  });

  // 守护「设置屏曾是孤儿屏、没入口」这个回归：shell 顶栏必须有齿轮入口。
  // 实际「点齿轮 → 打开设置屏」的导航由 web 手测验收（测试桩下 Drift 流 +
  // 设置屏 TextField 光标会让 settle 永不结束，导航断言在此环境不稳）。
  testWidgets('shell 顶栏有设置入口齿轮', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('open-settings')), findsOneWidget);

    await db.close();
    await tester.pump();
  });
}
