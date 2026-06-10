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

  test('FailureReason 映射到福格要素中文名（动机/能力/提示）', () {
    expect(FailureReason.noMotivation.foggFactorName, '动机');
    expect(FailureReason.tired.foggFactorName, '能力');
    expect(FailureReason.forgot.foggFactorName, '提示');
  });

  test('TaskEventType.tomatoAbort 追加在末尾、index=4', () {
    expect(TaskEventType.tomatoAbort.index, 4);
    expect(TaskEventType.values.length, 5);
  });

  test('TaskSource.capture 追加在末尾、index=2', () {
    expect(TaskSource.values.length, 3);
    expect(TaskSource.capture.index, 2);
    // 既有值索引不变（intEnum 存的是 index，不能挪动）
    expect(TaskSource.manual.index, 0);
    expect(TaskSource.feishu.index, 1);
  });
}
