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
          tomatoDone: 0,
          tomatoEst: null,
          onToggle: () => toggled = true,
          onFocus: () {},
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
          tomatoDone: 0,
          tomatoEst: null,
          onToggle: () {},
          onFocus: () {},
        ),
      ),
    ));
    expect(find.textContaining('已推迟 2 次'), findsOneWidget);
  });

  testWidgets('显示 🍅 数 + 点击发起 onFocus', (tester) async {
    var focused = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '写 Java 代码',
          domain: '工作',
          done: false,
          overdue: false,
          rolloverCount: 0,
          tomatoDone: 1,
          tomatoEst: 3,
          onToggle: () {},
          onFocus: () => focused = true,
        ),
      ),
    ));
    expect(find.textContaining('🍅'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('todo-focus')));
    expect(focused, true);
  });

  testWidgets('传 diagnosisLabel → 显诊断；不传 → 无', (tester) async {
    Widget card({String? diag}) => MaterialApp(
          home: Scaffold(
            body: TodoCard(
              title: '写 Java 代码',
              domain: '工作',
              done: false,
              overdue: false,
              rolloverCount: 0,
              diagnosisLabel: diag,
              tomatoDone: 0,
              tomatoEst: null,
              onToggle: () {},
              onFocus: () {},
            ),
          ),
        );

    await tester.pumpWidget(card(diag: '总卡在「能力·A」'));
    expect(find.textContaining('🩺'), findsOneWidget);
    expect(find.textContaining('总卡在「能力·A」'), findsOneWidget);

    await tester.pumpWidget(card());
    expect(find.textContaining('🩺'), findsNothing);
  });
}
