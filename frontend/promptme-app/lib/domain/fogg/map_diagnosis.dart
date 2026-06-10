import '../enums.dart';

/// 任务级 MAP 诊断：把历次「太难了」的失败原因(P/A/M)累积成主因。
/// 纯派生（从 TaskEvents 的 tooHard.reason 计数），无状态、无 schema。
class MapDiagnosis {
  const MapDiagnosis(this.counts, this.dominant);

  final Map<FailureReason, int> counts;

  /// 唯一最高的失败要素；总数 <2 或平票时为 null（只暴露清晰模式）。
  final FailureReason? dominant;

  int get total => counts.values.fold(0, (a, b) => a + b);

  /// 卡片展示文案；无主因时为 null。
  String? get label => dominant == null
      ? null
      : '总卡在「${dominant!.foggFactorName}·${dominant!.foggFactor}」';

  static MapDiagnosis from(Iterable<FailureReason> reasons) {
    final counts = <FailureReason, int>{};
    for (final r in reasons) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    FailureReason? dominant;
    if (total >= 2) {
      final max = counts.values.reduce((a, b) => a > b ? a : b);
      final tops = counts.entries.where((e) => e.value == max).toList();
      if (tops.length == 1) dominant = tops.first.key; // 平票 → 不给主因
    }
    return MapDiagnosis(counts, dominant);
  }
}
