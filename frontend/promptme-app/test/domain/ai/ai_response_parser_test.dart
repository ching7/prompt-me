import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/ai/ai_response_parser.dart';

void main() {
  test('parses prioritize JSON even when wrapped in prose/fences', () {
    const raw = '''
好的，这是结果：
```json
{
  "suggestions": [
    {"task": "项目周报", "quadrant": "重要紧急", "reason": "今天有deadline"}
  ],
  "todayFocus": ["项目周报"]
}
```
''';
    final r = AiResponseParser.parsePrioritize(raw);
    expect(r.suggestions.single.taskTitle, '项目周报');
    expect(r.suggestions.single.quadrant, Quadrant.importantUrgent);
    expect(r.todayFocus, ['项目周报']);
  });

  test('parses review JSON array', () {
    const raw =
        '[{"task":"项目周报","diagnosis":"任务太大","fogg":"A","suggestion":"拆成2分钟"}]';
    final items = AiResponseParser.parseReview(raw);
    expect(items.single.taskTitle, '项目周报');
    expect(items.single.foggFactor, 'A');
    expect(items.single.suggestion, '拆成2分钟');
  });
}
