import '../enums.dart';
import 'parsed_task.dart';

/// 把飞书文档导出的 Markdown 解析为「日期 + 四象限 + 嵌套 checkbox」的任务树。
class FeishuMarkdownParser {
  static final _checkbox = RegExp(r'^(\s*)[-*]\s*\[([ xX])\]\s+(.*)$');

  static List<ParsedTask> parse(String markdown, {required int year}) {
    final roots = <ParsedTask>[];
    final stack = <({int depth, ParsedTask task})>[];
    DateTime? currentDate;
    var currentQuadrant = Quadrant.importantNotUrgent; // 未声明象限时的默认桶

    for (final line in markdown.split('\n')) {
      if (line.trim().isEmpty) continue;

      final cb = _checkbox.firstMatch(line);
      if (cb != null) {
        final indent = cb.group(1)!.replaceAll('\t', '  ').length;
        final depth = indent ~/ 2;
        final done = cb.group(2)!.toLowerCase() == 'x';
        final title = cb.group(3)!.trim();
        final task = ParsedTask(
          title: title,
          quadrant: currentQuadrant,
          date: currentDate,
          done: done,
        );
        while (stack.isNotEmpty && stack.last.depth >= depth) {
          stack.removeLast();
        }
        if (stack.isEmpty) {
          roots.add(task);
        } else {
          stack.last.task.children.add(task);
        }
        stack.add((depth: depth, task: task));
        continue;
      }

      final text = line
          .trim()
          .replaceAll(RegExp(r'^[#>*\s\-]+'), '')
          .replaceAll(RegExp(r'[*#\s]+$'), '');

      final date = _parseDate(text, year);
      if (date != null) {
        currentDate = date;
        stack.clear();
        continue;
      }
      final q = Quadrant.fromLabel(text);
      if (q != null) {
        currentQuadrant = q;
        stack.clear();
        continue;
      }
    }
    return roots;
  }

  static DateTime? _parseDate(String text, int year) {
    final m = RegExp(r'^(\d{1,2})月?(\d{1,2})日?$').firstMatch(text);
    if (m == null) return null;
    final mm = int.parse(m.group(1)!);
    final dd = int.parse(m.group(2)!);
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    return DateTime(year, mm, dd);
  }
}
