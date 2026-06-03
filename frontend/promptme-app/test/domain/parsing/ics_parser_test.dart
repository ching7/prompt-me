import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/parsing/ics_parser.dart';

const _ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:evt-1
SUMMARY:周报
DTSTART:20260603T020000Z
DTEND:20260603T033000Z
END:VEVENT
BEGIN:VEVENT
UID:evt-2
SUMMARY:芒种
DTSTART;VALUE=DATE:20260605
END:VEVENT
BEGIN:VEVENT
UID:evt-3
SUMMARY:长标题被折\\n行
 续行内容
DTSTART:20260603T090000
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('parses timed, all-day and folded events', () {
    final events = IcsParser.parse(_ics);
    expect(events.length, 3);

    final report = events.firstWhere((e) => e.uid == 'evt-1');
    expect(report.title, '周报');
    expect(report.allDay, isFalse);
    expect(report.end, isNotNull);

    final allDay = events.firstWhere((e) => e.uid == 'evt-2');
    expect(allDay.allDay, isTrue);
    expect(allDay.start, DateTime(2026, 6, 5));

    final folded = events.firstWhere((e) => e.uid == 'evt-3');
    expect(folded.title.contains('续行内容'), isTrue);
    expect(folded.start, DateTime(2026, 6, 3, 9, 0, 0));
  });
}
