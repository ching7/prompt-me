import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/today/widgets/celebration_overlay.dart';

void main() {
  // 庆祝层有彩纸动画 + 1.9s 自动消失定时器；断言后 pump 过这些时长把定时器跑完，
  // 不用 pumpAndSettle（confetti 持续动画会挂）。
  testWidgets('传 pointsDelta 时显示 +N 分', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CelebrationOverlay(streak: 1, pointsDelta: 10, onDismiss: () {}),
    ));
    await tester.pump();
    expect(find.textContaining('+10 分'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // 跑完 1.9s 定时器
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('不传 pointsDelta 时不显示 +N 分', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CelebrationOverlay(streak: 1, onDismiss: () {}),
    ));
    await tester.pump();
    expect(find.textContaining('分'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
  });
}
