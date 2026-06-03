import 'package:drift/drift.dart';
import '../database.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [Subscriptions, CalendarEvents])
class CalendarDao extends DatabaseAccessor<AppDatabase> with _$CalendarDaoMixin {
  CalendarDao(super.db);

  Future<int> addSubscription(SubscriptionsCompanion sub) =>
      into(subscriptions).insert(sub);

  Future<List<Subscription>> subscriptionsList() => select(subscriptions).get();

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
}
