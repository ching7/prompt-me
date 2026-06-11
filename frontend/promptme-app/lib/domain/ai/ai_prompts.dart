class AiPrompts {
  static String prioritize({
    required List<String> taskTitles,
    required List<String> todayEvents,
  }) {
    final tasks = taskTitles.map((t) => '- $t').join('\n');
    final events =
        todayEvents.isEmpty ? '（今天无日程）' : todayEvents.map((e) => '- $e').join('\n');
    return '''
你是个人效率教练，使用艾森豪威尔四象限。
今天的日程：
$events

待办任务：
$tasks

请输出 JSON：
{"suggestions":[{"task":"任务原文","quadrant":"重要紧急|重要非紧急|不重要紧急|不重要不紧急","reason":"一句话理由"}],
"todayFocus":["最多3个今天必须先做的任务原文"]}
只输出 JSON。''';
  }

  static String estimateTomato(String taskTitle) {
    return '''
你是番茄工作法教练。一个番茄 = 25 分钟专注。
任务：$taskTitle
请估计完成它大约需要几个番茄（1 到 4 的整数，超过 4 也按 4 算）。
只输出一个数字，不要任何其它文字。''';
  }

  static String review({required List<String> overdueDescriptions}) {
    final list = overdueDescriptions.map((d) => '- $d').join('\n');
    return '''
你是福格行为模型(B=MAP)教练。下面是用户未完成/过期的任务及信号：
$list

针对每条，判断失败的是 M(动机)/A(能力)/P(提示) 哪个，并给一个具体可执行的调整。
输出 JSON 数组：
[{"task":"任务原文","diagnosis":"原因","fogg":"M|A|P","suggestion":"一个具体调整"}]
只输出 JSON。''';
  }
}
