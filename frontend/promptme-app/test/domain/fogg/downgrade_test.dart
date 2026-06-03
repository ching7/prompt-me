import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/downgrade.dart';

void main() {
  test('local fallback shrinks deterministically by level', () {
    final l1 = Downgrade.localFallback('完成项目周报', 1);
    final l2 = Downgrade.localFallback('完成项目周报', 2);
    expect(l1, contains('2 分钟'));
    expect(l1, contains('完成项目周报'));
    expect(l1, isNot(equals(l2)));
  });

  test('prompt mentions task, reason and fogg factor', () {
    final p = Downgrade.buildPrompt(
      taskTitle: '完成项目周报',
      reason: FailureReason.tired,
      level: 1,
    );
    expect(p, contains('完成项目周报'));
    expect(p, contains('太累'));
    expect(p, contains('A'));
  });
}
