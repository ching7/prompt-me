import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/todo/too_hard_sheet.dart';

void main() {
  testWidgets('点「太累了」回调 FailureReason.tired', (tester) async {
    FailureReason? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TooHardSheet(
          taskTitle: '写 Java 代码',
          onReason: (r) => got = r,
        ),
      ),
    ));
    expect(find.textContaining('太难了'), findsOneWidget);
    expect(find.textContaining('写 Java 代码'), findsOneWidget);
    await tester.tap(find.text('太累了'));
    await tester.pump();
    expect(got, FailureReason.tired);
  });

  testWidgets('三个原因都在', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TooHardSheet(taskTitle: 'x', onReason: (_) {}),
      ),
    ));
    expect(find.text('忘记了'), findsOneWidget);
    expect(find.text('太累了'), findsOneWidget);
    expect(find.text('没动力'), findsOneWidget);
  });
}
