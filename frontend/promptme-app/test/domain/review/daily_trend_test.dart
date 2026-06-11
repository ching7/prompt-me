import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/review/daily_trend.dart';

void main() {
  final end = DateTime(2026, 6, 11); // 固定「今天」，避免依赖真实时钟

  ({TaskEventType type, DateTime at}) ev(TaskEventType t, DateTime at) =>
      (type: t, at: at);

  test('定长 days、旧→新、末位是 endDate', () {
    final out = DailyTrend.lastNDays(const [], end, days: 14);
    expect(out.length, 14);
    expect(out.first.date, DateTime(2026, 5, 29)); // 14 天含今天
    expect(out.last.date, DateTime(2026, 6, 11));
    // 旧→新单调
    for (var i = 1; i < out.length; i++) {
      expect(out[i].date.isAfter(out[i - 1].date), isTrue);
    }
  });

  test('按天聚合积分/完成/番茄/太难了', () {
    final events = [
      ev(TaskEventType.done, DateTime(2026, 6, 11, 9)), // +10 done
      ev(TaskEventType.tomato, DateTime(2026, 6, 11, 10)), // +10 tomato
      ev(TaskEventType.capture, DateTime(2026, 6, 11, 8)), // +2
      ev(TaskEventType.tooHard, DateTime(2026, 6, 11, 11)), // +0
      ev(TaskEventType.tomatoAbort, DateTime(2026, 6, 11, 12)), // +0
      ev(TaskEventType.done, DateTime(2026, 6, 10, 9)), // 昨天 +10
    ];
    final out = DailyTrend.lastNDays(events, end, days: 14);
    final today = out.last;
    expect(today.points, 22); // 10+10+2
    expect(today.done, 1);
    expect(today.tomato, 1);
    expect(today.tooHard, 1);

    final yesterday = out[out.length - 2];
    expect(yesterday.points, 10);
    expect(yesterday.done, 1);
  });

  test('窗口外事件忽略', () {
    final events = [
      ev(TaskEventType.done, DateTime(2026, 5, 1)), // 远早于窗口
      ev(TaskEventType.done, DateTime(2026, 7, 1)), // 未来
    ];
    final out = DailyTrend.lastNDays(events, end, days: 14);
    expect(out.every((d) => d.points == 0), isTrue);
  });

  test('空日 isEmpty 为真', () {
    final out = DailyTrend.lastNDays(const [], end, days: 3);
    expect(out.every((d) => d.isEmpty), isTrue);
  });
}
