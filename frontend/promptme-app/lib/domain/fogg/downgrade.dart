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
  /// 关键：按塌掉的福格要素(M/A/P)对症下药——不同要素用不同降级策略。
  static String buildPrompt({
    required String taskTitle,
    required FailureReason reason,
    required int level,
  }) {
    return '你是福格行为模型(B=MAP / Tiny Habits)教练。\n'
        '用户的任务「$taskTitle」这次没做成，原因是「${reason.label}」——'
        '塌掉的福格要素是【${reason.foggFactorName}·${reason.foggFactor}】。\n'
        '请据此「对症降级」，生成一个 2 分钟内、几乎不可能失败的微习惯，'
        '遵循该要素对应的策略：\n'
        '${_strategyFor(reason)}\n'
        '当前降级层级 $level（层级越高，微习惯要更小、更具体、更易起步）。\n'
        '要求：保留原任务的方向（别换成无关的事）；'
        '只输出一行中文微习惯本身，不要解释、不要前缀、不要引号。';
  }

  /// 每个福格要素塌掉时的降级策略（喂给模型，使微习惯对症）。
  static String _strategyFor(FailureReason reason) => switch (reason) {
        // A 能力塌：任务超出当下能力 → 砍范围/时长/难度。
        FailureReason.tired => '能力塌：把范围、时长、难度砍到「再累也能完成」'
            '——只做第一步、只做一个最小单位、或只做 2 分钟就停。',
        // M 动机塌：别靠意志 → 小到不需要动力，并点出即时好处。
        FailureReason.noMotivation => '动机塌：缩到「小到不需要动力就能起步」，'
            '并轻轻点出做这一步的即时好处或意义，让人愿意开始。',
        // P 提示塌：缺触发 → 绑一个明确锚点。
        FailureReason.forgot => '提示塌：给它绑一个明确的触发锚点'
            '（在某件已有日常之后立刻做），让它有个固定的启动信号。',
      };
}
