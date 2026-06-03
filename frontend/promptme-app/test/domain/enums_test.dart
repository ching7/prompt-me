import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';

void main() {
  group('Quadrant.fromLabel', () {
    test('matches plain and decorated labels', () {
      expect(Quadrant.fromLabel('重要紧急'), Quadrant.importantUrgent);
      expect(Quadrant.fromLabel('重要 · 紧急'), Quadrant.importantUrgent);
      expect(Quadrant.fromLabel('不重要不紧急'), Quadrant.notImportantNotUrgent);
      expect(Quadrant.fromLabel('随便'), isNull);
    });
    test('priority puts importantUrgent first', () {
      final sorted = [...Quadrant.values]..sort((a, b) => a.priority - b.priority);
      expect(sorted.first, Quadrant.importantUrgent);
    });
  });

  test('FailureReason maps to fogg factor', () {
    expect(FailureReason.forgot.foggFactor, 'P');
    expect(FailureReason.tired.foggFactor, 'A');
    expect(FailureReason.noMotivation.foggFactor, 'M');
  });
}
