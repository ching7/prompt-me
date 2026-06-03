import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/ai/ai_prompts.dart';

void main() {
  test('prioritize prompt lists tasks and events', () {
    final p = AiPrompts.prioritize(
      taskTitles: ['农信问题', '郑州银行'],
      todayEvents: ['10:00 周报'],
    );
    expect(p, contains('农信问题'));
    expect(p, contains('郑州银行'));
    expect(p, contains('周报'));
    expect(p, contains('四象限'));
  });

  test('review prompt lists overdue descriptions', () {
    final p = AiPrompts.review(overdueDescriptions: ['农信问题（被推迟3次，重要紧急）']);
    expect(p, contains('被推迟3次'));
  });
}
