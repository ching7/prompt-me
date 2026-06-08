import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/shell/home_shell.dart';

void main() {
  testWidgets('三 Tab 默认在待办、可切到收件箱与复盘', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    // 底部三个 Tab 标签都在
    expect(find.text('收件箱'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);

    // 默认选中「待办」→ 待办占位屏标题可见
    expect(find.text('待办 · 占位'), findsOneWidget);

    // 切到收件箱
    await tester.tap(find.text('收件箱'));
    await tester.pumpAndSettle();
    expect(find.text('收件箱 · 占位'), findsOneWidget);

    // 切到复盘
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('复盘 · 占位'), findsOneWidget);
  });
}
