import '../enums.dart';

class Downgrade {
  /// AI 不可用时的确定性兜底；层级越高任务越小（无底线）。
  static String localFallback(String taskTitle, int level) {
    final clean = taskTitle.trim();
    return switch (level) {
      <= 1 => '只打开《$clean》，做满 2 分钟就停。',
      2 => '只看一眼《$clean》，读懂第一行就算赢。',
      _ => '现在对《$clean》说一句「我等下做」，然后深呼吸一次。',
    };
  }

  /// 让 AI 生成 2 分钟微习惯的提示词。
  static String buildPrompt({
    required String taskTitle,
    required FailureReason reason,
    required int level,
  }) {
    return '你是福格行为模型(Tiny Habits)教练。'
        '用户的任务「$taskTitle」没能完成，原因是「${reason.label}」'
        '（失败的福格要素是 ${reason.foggFactor}）。'
        '请把它"无底线降级"为一个 2 分钟内、几乎不可能失败的微习惯'
        '（当前降级层级 $level，层级越高越小）。'
        '只输出一行中文微习惯本身，不要任何解释或前缀。';
  }
}
