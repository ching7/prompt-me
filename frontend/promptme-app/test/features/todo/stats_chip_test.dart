import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/todo/stats_chip.dart';

void main() {
  testWidgets('显示连续天数与今日完成', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsChip(streak: 7, done: 2, total: 5, points: 0)),
    ));
    expect(find.textContaining('7'), findsWidgets); // 🔥7
    expect(find.textContaining('2/5'), findsOneWidget); // ◎2/5
  });

  testWidgets('显示 ★总积分', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsChip(streak: 3, done: 2, total: 5, points: 42)),
    ));
    expect(find.textContaining('★42'), findsOneWidget);
  });
}
