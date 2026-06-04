import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/services/calendar_subscription_service.dart';

const _ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:e1
SUMMARY:周报
DTSTART:20260603T020000Z
DTEND:20260603T033000Z
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('fetch parses ICS and replaces events for a subscription', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));

    final client =
        MockClient((req) async => http.Response.bytes(utf8.encode(_ics), 200));
    final svc = CalendarSubscriptionService(db, client: client);

    await svc.refresh(subId, 'https://x/ics');

    final events = await db.calendarDao.eventsForDate(DateTime(2026, 6, 3));
    expect(events.single.title, '周报');
    final sub = (await db.calendarDao.subscriptionsList()).single;
    expect(sub.lastFetchedAt, isNotNull);
  });

  test('non-200 throws and does not wipe existing events', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));
    final ok =
        MockClient((req) async => http.Response.bytes(utf8.encode(_ics), 200));
    await CalendarSubscriptionService(db, client: ok).refresh(subId, 'https://x/ics');

    final bad = MockClient((req) async => http.Response('err', 500));
    await expectLater(
      CalendarSubscriptionService(db, client: bad).refresh(subId, 'https://x/ics'),
      throwsA(isA<Exception>()),
    );
    // 旧数据仍在
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 1);
  });
}
