import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import '../data/database.dart';
import '../domain/parsing/ics_parser.dart';

class CalendarSubscriptionService {
  CalendarSubscriptionService(this.db, {http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase db;
  final http.Client _client;

  /// 拉取一个 webcal/已发布 ICS 链接并替换该订阅的全部事件，返回解析到的事件总数。
  /// 失败时抛异常且不动旧数据（先解析成功再写库）。
  Future<int> refresh(int subscriptionId, String url) async {
    final uri = Uri.parse(url.replaceFirst('webcal://', 'https://'));
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('订阅拉取失败 HTTP ${resp.statusCode}');
    }
    // iCloud/飞书发布的 ICS 一律 UTF-8；直接按字节 UTF-8 解码，不依赖 charset 头。
    final parsed = IcsParser.parse(utf8.decode(resp.bodyBytes, allowMalformed: true));
    final companions = parsed
        .map((e) => CalendarEventsCompanion.insert(
              subscriptionId: subscriptionId,
              uid: e.uid,
              title: e.title,
              start: e.start,
              end: Value(e.end),
              allDay: Value(e.allDay),
            ))
        .toList();
    await db.calendarDao.replaceEvents(subscriptionId, companions);
    await (db.update(db.subscriptions)
          ..where((s) => s.id.equals(subscriptionId)))
        .write(SubscriptionsCompanion(lastFetchedAt: Value(DateTime.now())));
    return parsed.length;
  }

  Future<void> refreshAll() async {
    for (final sub in await db.calendarDao.subscriptionsList()) {
      try {
        await refresh(sub.id, sub.url);
      } catch (_) {
        // 单个失败不影响其它；UI 层另行提示
      }
    }
  }
}
