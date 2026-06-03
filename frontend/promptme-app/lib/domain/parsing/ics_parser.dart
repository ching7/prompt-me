import 'parsed_event.dart';

/// 极简 iCalendar 解析：满足苹果「已发布日历」订阅源（webcal）所需。
/// 处理：行折叠、VEVENT、UID/SUMMARY/DTSTART/DTEND、全天(VALUE=DATE)、UTC(Z)。
class IcsParser {
  static List<ParsedEvent> parse(String ics) {
    final lines = _unfold(ics);
    final events = <ParsedEvent>[];

    String? uid, summary;
    DateTime? start, end;
    var allDay = false;
    var inEvent = false;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = summary = null;
        start = end = null;
        allDay = false;
        continue;
      }
      if (line == 'END:VEVENT') {
        if (inEvent && start != null) {
          events.add(ParsedEvent(
            uid: uid ?? '${summary ?? 'evt'}_${start.millisecondsSinceEpoch}',
            title: summary ?? '(无标题)',
            start: start,
            end: end,
            allDay: allDay,
          ));
        }
        inEvent = false;
        continue;
      }
      if (!inEvent) continue;

      final idx = line.indexOf(':');
      if (idx < 0) continue;
      final rawKey = line.substring(0, idx);
      final value = line.substring(idx + 1);
      final key = rawKey.split(';').first.toUpperCase();

      switch (key) {
        case 'UID':
          uid = value.trim();
        case 'SUMMARY':
          summary = _unescape(value);
        case 'DTSTART':
          allDay = rawKey.toUpperCase().contains('VALUE=DATE') ||
              value.trim().length == 8;
          start = _parseDt(value);
        case 'DTEND':
          end = _parseDt(value);
      }
    }
    return events;
  }

  static List<String> _unfold(String ics) {
    final out = <String>[];
    for (final raw in ics.split(RegExp(r'\r?\n'))) {
      if ((raw.startsWith(' ') || raw.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] += raw.substring(1);
      } else {
        out.add(raw);
      }
    }
    return out;
  }

  static String _unescape(String v) => v
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');

  static DateTime? _parseDt(String value) {
    final s = value.trim();
    final date = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(s);
    if (date != null) {
      return DateTime(int.parse(date.group(1)!), int.parse(date.group(2)!),
          int.parse(date.group(3)!));
    }
    final dt =
        RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$').firstMatch(s);
    if (dt != null) {
      final y = int.parse(dt.group(1)!);
      final mo = int.parse(dt.group(2)!);
      final da = int.parse(dt.group(3)!);
      final h = int.parse(dt.group(4)!);
      final mi = int.parse(dt.group(5)!);
      final se = int.parse(dt.group(6)!);
      if (dt.group(7) == 'Z') {
        return DateTime.utc(y, mo, da, h, mi, se).toLocal();
      }
      return DateTime(y, mo, da, h, mi, se);
    }
    return null;
  }
}
