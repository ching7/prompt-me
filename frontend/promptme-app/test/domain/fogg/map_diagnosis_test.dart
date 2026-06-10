import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/map_diagnosis.dart';

void main() {
  test('主因 = 唯一最高（≥2 次）', () {
    final d = MapDiagnosis.from(
        [FailureReason.tired, FailureReason.tired, FailureReason.forgot]);
    expect(d.dominant, FailureReason.tired);
    expect(d.total, 3);
    expect(d.label, contains('能力'));
  });

  test('平票 → 无主因（不暴露模糊模式）', () {
    final d = MapDiagnosis.from([FailureReason.tired, FailureReason.forgot]);
    expect(d.dominant, isNull);
    expect(d.label, isNull);
  });

  test('不足 2 次 → 无主因', () {
    expect(MapDiagnosis.from([FailureReason.tired]).dominant, isNull);
    expect(MapDiagnosis.from(const []).dominant, isNull);
  });
}
