import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/import/feishu_importer.dart';

const _md = '''
# 0603
## 重要紧急
- [ ] 完成项目周报
  - [ ] 汇总本周进展
## 重要非紧急
- [x] 推进读书计划
''';

void main() {
  test('imports tasks for a target date with quadrant, source, parent links', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final count = await FeishuImporter(db)
        .import(_md, targetDate: DateTime(2026, 6, 3));
    expect(count, 3);

    final rows = await db.taskDao.tasksForDate(DateTime(2026, 6, 3));
    final parent = rows.firstWhere((t) => t.title == '完成项目周报');
    expect(parent.quadrant, Quadrant.importantUrgent);
    expect(parent.source, TaskSource.feishu);

    final child = rows.firstWhere((t) => t.title == '汇总本周进展');
    expect(child.parentTaskId, parent.id);

    final done = rows.firstWhere((t) => t.title == '推进读书计划');
    expect(done.status, TaskStatus.done);
    expect(done.quadrant, Quadrant.importantNotUrgent);
  });

  test('only imports the section matching targetDate', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const md = '# 0603\n## 重要紧急\n- [ ] A\n# 0602\n## 重要紧急\n- [ ] B';
    await FeishuImporter(db).import(md, targetDate: DateTime(2026, 6, 3));
    final rows = await db.taskDao.tasksForDate(DateTime(2026, 6, 3));
    expect(rows.map((t) => t.title), ['A']);
  });
}
