import 'package:drift/drift.dart';
import '../database.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [Subscriptions, CalendarEvents])
class CalendarDao extends DatabaseAccessor<AppDatabase> with _$CalendarDaoMixin {
  CalendarDao(super.db);

  Future<int> addSubscription(SubscriptionsCompanion sub) =>
      into(subscriptions).insert(sub);

  Future<List<Subscription>> subscriptionsList() => select(subscriptions).get();

  Stream<List<Subscription>> watchSubscriptions() => select(subscriptions).watch();

  /// 删除一个订阅及其全部事件。
  Future<void> deleteSubscription(int id) async {
    await transaction(() async {
      await (delete(calendarEvents)..where((e) => e.subscriptionId.equals(id)))
          .go();
      await (delete(subscriptions)..where((s) => s.id.equals(id))).go();
    });
  }

  /// 某事件数：用于订阅列表展示。
  Future<int> eventCountFor(int subscriptionId) async {
    final rows = await (select(calendarEvents)
          ..where((e) => e.subscriptionId.equals(subscriptionId)))
        .get();
    return rows.length;
  }

  /// 用最新拉取结果替换某订阅源的全部事件。
  Future<void> replaceEvents(
      int subscriptionId, List<CalendarEventsCompanion> events) async {
    await transaction(() async {
      await (delete(calendarEvents)
            ..where((e) => e.subscriptionId.equals(subscriptionId)))
          .go();
      await batch((b) => b.insertAll(calendarEvents, events));
    });
  }

  Future<List<CalendarEvent>> eventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where((e) =>
              e.start.isBiggerOrEqualValue(start) &
              e.start.isSmallerThanValue(end)))
        .get();
  }

  /// 同 [eventsForDate]，但随 calendar_events 表变化实时发射（订阅拉取后今日屏需刷新）。
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where((e) =>
              e.start.isBiggerOrEqualValue(start) &
              e.start.isSmallerThanValue(end)))
        .watch();
  }
}
