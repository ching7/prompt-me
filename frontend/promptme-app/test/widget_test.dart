import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/shell/home_shell.dart';

void main() {
  testWidgets('app boots to HomeShell with three tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('收件箱'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);
    expect(find.text('待办 · 占位'), findsOneWidget); // 默认选中「待办」
  });
}
