import '../enums.dart';

/// 总积分 = 各正向事件求和（纯函数，事件派生的单一真相源）。
/// 数值集中在此，便于后续调档 / 加连击加成。
class ScoreCalculator {
  static const int capturePoints = 2;
  static const int donePoints = 10;
  static const int tomatoPoints = 10;

  static int pointsFor(TaskEventType type) => switch (type) {
        TaskEventType.capture => capturePoints,
        TaskEventType.done => donePoints,
        TaskEventType.tomato => tomatoPoints,
        TaskEventType.tooHard => 0,
        TaskEventType.tomatoAbort => 0, // 放弃番茄不加分
      };

  static int total(Iterable<TaskEventType> types) =>
      types.fold(0, (sum, t) => sum + pointsFor(t));
}
