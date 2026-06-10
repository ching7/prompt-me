import '../fogg/map_diagnosis.dart';

/// 复盘数据汇总：今日为主（完成/番茄/太难了）+ 累计 MAP 主因作背景。
/// 纯派生（由 provider 从 TaskEvents 聚合喂入），无状态。
class ReviewStats {
  const ReviewStats({
    required this.todayDone,
    required this.todayTomato,
    required this.todayTooHard,
    required this.mapOverall,
  });

  final int todayDone;
  final int todayTomato;
  final int todayTooHard;

  /// 累计所有「太难了」失败要素的诊断（背景模式）。
  final MapDiagnosis mapOverall;
}
