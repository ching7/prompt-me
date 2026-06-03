import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/fogg/streak_calculator.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 6, day);

  test('counts consecutive days ending today', () {
    final days = {d(1), d(2), d(3)};
    expect(StreakCalculator.currentStreak(days, d(3)), 3);
  });

  test('a gap breaks the streak', () {
    final days = {d(1), d(3)};
    expect(StreakCalculator.currentStreak(days, d(3)), 1);
  });

  test('today empty but yesterday done keeps streak alive', () {
    final days = {d(1), d(2)};
    expect(StreakCalculator.currentStreak(days, d(3)), 2);
  });

  test('no activity yields zero', () {
    expect(StreakCalculator.currentStreak({}, d(3)), 0);
  });

  test('completion rate', () {
    expect(StreakCalculator.completionRate(done: 2, total: 5), closeTo(0.4, 1e-9));
    expect(StreakCalculator.completionRate(done: 0, total: 0), 0);
  });
}
