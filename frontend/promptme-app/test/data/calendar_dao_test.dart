import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('replaceEvents is idempotent per subscription', () async {
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));

    CalendarEventsCompanion ev(String uid, int hour) =>
        CalendarEventsCompanion.insert(
          subscriptionId: subId,
          uid: uid,
          title: '周报',
          start: DateTime(2026, 6, 3, hour),
        );

    await db.calendarDao.replaceEvents(subId, [ev('a', 10), ev('b', 11)]);
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 2);

    // 再拉一次（替换，不应翻倍）
    await db.calendarDao.replaceEvents(subId, [ev('a', 10)]);
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 1);
  });
}
