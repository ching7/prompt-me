import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/todo/todo_card.dart';

void main() {
  testWidgets('显示标题 + 领域 + 点击勾选回调', (tester) async {
    var toggled = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '写 Java 代码',
          domain: '工作',
          done: false,
          overdue: false,
          rolloverCount: 0,
          onToggle: () => toggled = true,
        ),
      ),
    ));
    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('todo-toggle')));
    expect(toggled, true);
  });

  testWidgets('逾期态显示已推迟次数', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '整理 API 文档',
          domain: null,
          done: false,
          overdue: true,
          rolloverCount: 2,
          onToggle: () {},
        ),
      ),
    ));
    expect(find.textContaining('已推迟 2 次'), findsOneWidget);
  });
}
