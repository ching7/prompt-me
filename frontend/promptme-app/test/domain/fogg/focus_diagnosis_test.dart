import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/focus_diagnosis.dart';

void main() {
  group('reasonForAbort', () {
    test('短放弃(<2min) → 动机塌(noMotivation)', () {
      expect(FocusDiagnosis.reasonForAbort(30), FailureReason.noMotivation);
      expect(FocusDiagnosis.reasonForAbort(119), FailureReason.noMotivation);
    });
    test('坚持一会儿才放弃(≥2min) → 能力塌(tired)', () {
      expect(FocusDiagnosis.reasonForAbort(120), FailureReason.tired);
      expect(FocusDiagnosis.reasonForAbort(600), FailureReason.tired);
    });
    test('时长缺失 → 无信号', () {
      expect(FocusDiagnosis.reasonForAbort(null), isNull);
    });
  });

  group('reasonsFrom', () {
    ({TaskEventType type, FailureReason? reason, int? durationSec}) e(
            TaskEventType t,
            {FailureReason? r, int? d}) =>
        (type: t, reason: r, durationSec: d);

    test('显式太难了 + 放弃时长 一起喂出', () {
      final reasons = FocusDiagnosis.reasonsFrom([
        e(TaskEventType.tooHard, r: FailureReason.tired),
        e(TaskEventType.tomatoAbort, d: 30), // → 动机
        e(TaskEventType.tomatoAbort, d: 300), // → 能力
        e(TaskEventType.done), // 忽略
        e(TaskEventType.tomatoAbort), // 无时长 → 忽略
      ]).toList();
      expect(reasons, [
        FailureReason.tired,
        FailureReason.noMotivation,
        FailureReason.tired,
      ]);
    });

    test('放弃但无时长 → 不产生信号', () {
      final reasons = FocusDiagnosis.reasonsFrom([
        e(TaskEventType.tomatoAbort),
        e(TaskEventType.tomatoAbort),
      ]).toList();
      expect(reasons, isEmpty);
    });
  });
}
