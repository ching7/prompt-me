import '../enums.dart';

/// 「专注时长二次喂诊断」：把番茄**放弃时长**也作为 MAP 诊断信号，
/// 与显式「太难了」原因一起喂给 [MapDiagnosis]，让卡片诊断更准。
///
/// 口径：放弃得越早越像「动机」塌（连开始都难）；坚持了一会儿才放弃更像「能力」塌（太难做不动）。
class FocusDiagnosis {
  /// 2 分钟内就放弃 ≈ 动机塌（没动力开始）；更久才放弃 ≈ 能力塌（做不动）。
  static const int shortAbortSec = 120;

  /// 一次放弃的时长 → 推断塌掉的福格要素。时长缺失（旧数据）→ 无信号。
  static FailureReason? reasonForAbort(int? durationSec) {
    if (durationSec == null) return null;
    return durationSec < shortAbortSec
        ? FailureReason.noMotivation // 几乎没开始 → 动机(M)
        : FailureReason.tired; // 开始了又放弃 → 能力(A)
  }

  /// 从一批事件抽出喂给 MapDiagnosis 的**全部**失败要素：
  /// 显式「太难了」原因 + 由放弃番茄时长推断的要素。
  static Iterable<FailureReason> reasonsFrom(
    Iterable<({TaskEventType type, FailureReason? reason, int? durationSec})>
        events,
  ) sync* {
    for (final e in events) {
      if (e.type == TaskEventType.tooHard && e.reason != null) {
        yield e.reason!;
      } else if (e.type == TaskEventType.tomatoAbort) {
        final r = reasonForAbort(e.durationSec);
        if (r != null) yield r;
      }
    }
  }
}
