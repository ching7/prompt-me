class ParsedEvent {
  final String uid;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;

  ParsedEvent({
    required this.uid,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
  });
}
