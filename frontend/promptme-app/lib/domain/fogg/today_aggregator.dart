import '../enums.dart';

class TodayEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarName;
  TodayEvent({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.calendarName,
  });
}

class TodayTask {
  final int id;
  final String title;
  final Quadrant quadrant;
  final bool done;
  TodayTask({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.done,
  });
}

class TodayView {
  final List<TodayEvent> events;
  final Map<Quadrant, List<TodayTask>> byQuadrant;
  final List<TodayTask> completed;
  final int doneCount;
  final int totalCount;
  TodayView({
    required this.events,
    required this.byQuadrant,
    required this.completed,
    required this.doneCount,
    required this.totalCount,
  });
}

class TodayAggregator {
  static TodayView build({
    required List<TodayEvent> events,
    required List<TodayTask> tasks,
  }) {
    final sortedEvents = [...events]..sort((a, b) => a.start.compareTo(b.start));

    final pending = tasks.where((t) => !t.done).toList();
    final completed = tasks.where((t) => t.done).toList();

    // Quadrant.values 已是优先级顺序（重要紧急在前），直接遍历，勿对 const 列表排序。
    final byQuadrant = <Quadrant, List<TodayTask>>{};
    for (final q in Quadrant.values) {
      byQuadrant[q] = pending.where((t) => t.quadrant == q).toList();
    }

    return TodayView(
      events: sortedEvents,
      byQuadrant: byQuadrant,
      completed: completed,
      doneCount: completed.length,
      totalCount: tasks.length,
    );
  }
}
