import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/parsing/feishu_markdown_parser.dart';

const _sample = '''
# 0603
## 重要紧急
- [ ] 完成项目周报
  - [ ] 汇总本周进展
  - [ ] 整理风险项
## 重要非紧急
- [ ] 推进读书计划
# 0602
## 重要紧急
- [x] 晨间锻炼20分钟
''';

void main() {
  test('parses dates, quadrants, nesting and done state', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);

    final gx = tasks.firstWhere((t) => t.title == '完成项目周报');
    expect(gx.quadrant, Quadrant.importantUrgent);
    expect(gx.date, DateTime(2026, 6, 3));
    expect(gx.done, isFalse);
    expect(gx.children.map((c) => c.title),
        ['汇总本周进展', '整理风险项']);

    final zz = tasks.firstWhere((t) => t.title == '推进读书计划');
    expect(zz.quadrant, Quadrant.importantNotUrgent);

    final done = tasks.firstWhere((t) => t.title == '晨间锻炼20分钟');
    expect(done.done, isTrue);
    expect(done.date, DateTime(2026, 6, 2));
  });

  test('only top-level tasks are returned as roots', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);
    expect(tasks.map((t) => t.title),
        containsAll(['完成项目周报', '推进读书计划', '晨间锻炼20分钟']));
    expect(tasks.any((t) => t.title == '汇总本周进展'), isFalse);
  });
}
