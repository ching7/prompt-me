import '../enums.dart';
import '../score/score_calculator.dart';

/// 某天的复盘数值（趋势曲线 / 历史小结派生用）。纯数据，无状态。
class DayStat {
  const DayStat({
    required this.date,
    required this.points,
    required this.done,
    required this.tomato,
    required this.tooHard,
  });

  final DateTime date; // 当天 0 点
  final int points;
  final int done;
  final int tomato;
  final int tooHard;

  bool get isEmpty => points == 0 && done == 0 && tomato == 0 && tooHard == 0;
}

/// 由全量事件聚合出「截至 endDate 的近 days 天」每日数值（旧→新，定长 days）。
/// 纯函数：UI 只管画，便于单测。窗口外事件忽略。
class DailyTrend {
  static List<DayStat> lastNDays(
    Iterable<({TaskEventType type, DateTime at})> events,
    DateTime endDate, {
    int days = 14,
  }) {
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final buckets = <DateTime, _Acc>{};
    final order = <DateTime>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = end.subtract(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day);
      buckets[key] = _Acc();
      order.add(key);
    }
    for (final e in events) {
      final key = DateTime(e.at.year, e.at.month, e.at.day);
      final acc = buckets[key];
      if (acc == null) continue; // 窗口外
      acc.points += ScoreCalculator.pointsFor(e.type);
      switch (e.type) {
        case TaskEventType.done:
          acc.done++;
        case TaskEventType.tomato:
          acc.tomato++;
        case TaskEventType.tooHard:
          acc.tooHard++;
        case TaskEventType.capture:
        case TaskEventType.tomatoAbort:
          break;
      }
    }
    return [
      for (final k in order)
        DayStat(
          date: k,
          points: buckets[k]!.points,
          done: buckets[k]!.done,
          tomato: buckets[k]!.tomato,
          tooHard: buckets[k]!.tooHard,
        ),
    ];
  }
}

class _Acc {
  int points = 0;
  int done = 0;
  int tomato = 0;
  int tooHard = 0;
}
