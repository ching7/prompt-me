import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/inbox/inbox_card.dart';

void main() {
  testWidgets('有领域显标签，无领域显未分类，含标题', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          InboxCard(title: '研究 MCP 协议', domain: '学习', subtitle: '💻 桌面 · 刚刚'),
          InboxCard(title: '没标签', domain: null, subtitle: '✍️ 手记 · 昨天'),
        ]),
      ),
    ));
    expect(find.text('研究 MCP 协议'), findsOneWidget);
    expect(find.textContaining('学习'), findsOneWidget); // 🏷 学习
    expect(find.text('没标签'), findsOneWidget);
    expect(find.textContaining('未分类'), findsOneWidget); // 🏷 未分类
  });
}
