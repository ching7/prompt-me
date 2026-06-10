import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/downgrade.dart';

void main() {
  test('local fallback shrinks deterministically by level', () {
    final l1 = Downgrade.localFallback('完成项目周报', 1);
    final l2 = Downgrade.localFallback('完成项目周报', 2);
    expect(l1, contains('2 分钟'));
    expect(l1, contains('完成项目周报'));
    expect(l1, isNot(equals(l2)));
  });

  test('prompt mentions task, reason and fogg factor', () {
    final p = Downgrade.buildPrompt(
      taskTitle: '完成项目周报',
      reason: FailureReason.tired,
      level: 1,
    );
    expect(p, contains('完成项目周报'));
    expect(p, contains('太累'));
    expect(p, contains('A'));
  });

  test('prompt 按塌掉的福格要素给对症策略（能力/动机/提示）', () {
    String p(FailureReason r) =>
        Downgrade.buildPrompt(taskTitle: '完成项目周报', reason: r, level: 1);

    // 能力塌（太累）→ 砍到再累也能做
    final a = p(FailureReason.tired);
    expect(a, contains('能力'));
    expect(a, contains('再累也能'));

    // 动机塌（没动力）→ 小到不需要动力
    final m = p(FailureReason.noMotivation);
    expect(m, contains('动机'));
    expect(m, contains('不需要动力'));

    // 提示塌（忘记）→ 绑触发锚点
    final pr = p(FailureReason.forgot);
    expect(pr, contains('提示'));
    expect(pr, contains('锚点'));
  });
}
