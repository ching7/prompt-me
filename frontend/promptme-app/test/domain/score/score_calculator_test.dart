import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/score/score_calculator.dart';

void main() {
  test('捕获+2 · 完成+10 · 番茄+10 · 太难了不计分', () {
    final types = [
      TaskEventType.capture, // +2
      TaskEventType.capture, // +2
      TaskEventType.done,    // +10
      TaskEventType.tomato,  // +10
      TaskEventType.tooHard, // +0
    ];
    expect(ScoreCalculator.total(types), 24);
  });

  test('空事件 = 0 分', () {
    expect(ScoreCalculator.total(const []), 0);
  });
}
