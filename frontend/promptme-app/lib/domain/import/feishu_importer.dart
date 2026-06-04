import 'package:drift/drift.dart' show Value;
import '../../data/database.dart';
import '../enums.dart';
import '../parsing/feishu_markdown_parser.dart';
import '../parsing/parsed_task.dart';

class FeishuImporter {
  FeishuImporter(this.db);
  final AppDatabase db;

  /// 解析飞书 Markdown，把整篇任务（含嵌套、含已完成）导入到 [targetDate]，返回导入条数。
  /// 粘贴导入是一次显式动作：忽略文档内部的日期标题，全部排到选定的当天。
  Future<int> import(String markdown, {required DateTime targetDate}) async {
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final roots = FeishuMarkdownParser.parse(markdown, year: day.year);

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
}
