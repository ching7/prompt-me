import 'package:drift/drift.dart' show Value;
import '../../data/database.dart';
import '../enums.dart';
import '../parsing/feishu_markdown_parser.dart';
import '../parsing/parsed_task.dart';

class FeishuImporter {
  FeishuImporter(this.db);
  final AppDatabase db;

  /// 解析飞书 Markdown，导入 [targetDate] 当天的任务（含嵌套），返回导入条数。
  Future<int> import(String markdown, {required DateTime targetDate}) async {
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final roots = FeishuMarkdownParser.parse(markdown, year: day.year)
        .where((t) => t.date == null || _sameDay(t.date!, day))
        .toList();

    var count = 0;
    Future<void> insertTree(ParsedTask node, int? parentId) async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
        title: node.title,
        quadrant: node.quadrant,
        source: TaskSource.feishu,
        scheduledDate: Value(day),
        firstScheduledDate: Value(day),
        parentTaskId: Value(parentId),
        status: Value(node.done ? TaskStatus.done : TaskStatus.pending),
        completedAt: Value(node.done ? day : null),
      ));
      count++;
      for (final child in node.children) {
        await insertTree(child, id);
      }
    }

    for (final root in roots) {
      await insertTree(root, null);
    }
    return count;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
