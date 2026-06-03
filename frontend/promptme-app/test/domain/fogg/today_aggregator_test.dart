import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/today_aggregator.dart';

void main() {
  test('sorts events, groups pending tasks by quadrant, sinks done', () {
    final events = [
      TodayEvent(title: '周报', start: DateTime(2026, 6, 3, 10), allDay: false),
      TodayEvent(title: '复盘', start: DateTime(2026, 6, 3, 9), allDay: false),
    ];
    final tasks = [
      TodayTask(id: 1, title: '郑州银行', quadrant: Quadrant.importantNotUrgent, done: false),
      TodayTask(id: 2, title: '农信问题', quadrant: Quadrant.importantUrgent, done: false),
      TodayTask(id: 3, title: '人员投入', quadrant: Quadrant.importantUrgent, done: true),
    ];

    final view = TodayAggregator.build(events: events, tasks: tasks);

    expect(view.events.first.title, '复盘'); // 按时间排序
    expect(view.byQuadrant[Quadrant.importantUrgent]!.map((t) => t.title), ['农信问题']);
    expect(view.byQuadrant[Quadrant.importantNotUrgent]!.map((t) => t.title), ['郑州银行']);
    expect(view.completed.map((t) => t.title), ['人员投入']);
    expect(view.doneCount, 1);
    expect(view.totalCount, 3);
  });
}
