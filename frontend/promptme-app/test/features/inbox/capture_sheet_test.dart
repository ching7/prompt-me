import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/inbox/capture_sheet.dart';

void main() {
  testWidgets('输入文本 + 选领域 → onCapture 回调带值', (tester) async {
    String? gotText;
    String? gotDomain;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CaptureSheet(onCapture: (t, d) {
          gotText = t;
          gotDomain = d;
        }),
      ),
    ));

    await tester.enterText(find.byType(TextField), '研究 MCP 协议');
    await tester.tap(find.text('学习'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '记一笔'));
    await tester.pump();

    expect(gotText, '研究 MCP 协议');
    expect(gotDomain, '学习');
  });

  testWidgets('空文本时「记一笔」不回调', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CaptureSheet(onCapture: (_, __) => called = true)),
    ));
    await tester.tap(find.widgetWithText(FilledButton, '记一笔'));
    await tester.pump();
    expect(called, false);
  });
}
