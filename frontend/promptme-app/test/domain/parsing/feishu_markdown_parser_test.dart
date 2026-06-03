import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/parsing/feishu_markdown_parser.dart';

const _sample = '''
# 0603
## 重要紧急
- [ ] 整理广西农信问题
  - [ ] 智算定制功能查看与了解
  - [ ] 星火智能体功能核对
## 重要非紧急
- [ ] 郑州银行进度跟踪
# 0602
## 重要紧急
- [x] 整理人员投入情况
''';

void main() {
  test('parses dates, quadrants, nesting and done state', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);

    final gx = tasks.firstWhere((t) => t.title == '整理广西农信问题');
    expect(gx.quadrant, Quadrant.importantUrgent);
    expect(gx.date, DateTime(2026, 6, 3));
    expect(gx.done, isFalse);
    expect(gx.children.map((c) => c.title),
        ['智算定制功能查看与了解', '星火智能体功能核对']);

    final zz = tasks.firstWhere((t) => t.title == '郑州银行进度跟踪');
    expect(zz.quadrant, Quadrant.importantNotUrgent);

    final done = tasks.firstWhere((t) => t.title == '整理人员投入情况');
    expect(done.done, isTrue);
    expect(done.date, DateTime(2026, 6, 2));
  });

  test('only top-level tasks are returned as roots', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);
    expect(tasks.map((t) => t.title),
        containsAll(['整理广西农信问题', '郑州银行进度跟踪', '整理人员投入情况']));
    expect(tasks.any((t) => t.title == '智算定制功能查看与了解'), isFalse);
  });
}
