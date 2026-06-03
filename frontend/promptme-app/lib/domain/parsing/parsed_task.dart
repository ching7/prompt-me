import '../enums.dart';

class ParsedTask {
  final String title;
  final Quadrant quadrant;
  final DateTime? date;
  final bool done;
  final List<ParsedTask> children;

  ParsedTask({
    required this.title,
    required this.quadrant,
    this.date,
    this.done = false,
    List<ParsedTask>? children,
  }) : children = children ?? [];
}
