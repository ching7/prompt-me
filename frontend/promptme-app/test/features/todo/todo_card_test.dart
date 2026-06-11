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
    expect(find.textContaining('工作'), findsOneWidget); // 🏷 工作（便签 chip）
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

  testWidgets('可操作番茄 chip 显 ▶ 图标（与只读提示 chip 区分）', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: 'A',
          domain: '工作',
          done: false,
          overdue: false,
          rolloverCount: 0,
          tomatoDone: 0,
          tomatoEst: null,
          onToggle: () {},
          onFocus: () {},
        ),
      ),
    ));
    // 番茄是唯一可操作 chip → 实底带 ▶；便签/领域只读 → 无 ▶
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('点卡身（非勾选/非番茄）→ onTap 回调', (tester) async {
    var tapped = false;
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
          onToggle: () {},
          onFocus: () {},
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.tap(find.text('写 Java 代码')); // 点标题=点卡身
    expect(tapped, true);
  });
}
