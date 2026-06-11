/// 番茄预估：AI 关或解析失败时的本地启发式（纯函数，1–4）。
/// 口径：默认 2；命中「大任务」词或标题长 → 3/4；命中「小事」词 → 1。
class TomatoEstimator {
  // 偏大的活儿（写作/汇报/方案/复习/学习类）：通常 ≥1.5 个番茄。
  static const _big = [
    '写', '报告', '周报', '方案', '复习', '学习', '研究', '设计',
    '项目', '论文', '总结', '准备', 'PPT', '调研', '读', '看书',
  ];
  // 一次就完的小事：1 个番茄足矣。
  static const _small = [
    '回复', '打卡', '喝水', '发', '提交', '确认', '预约', '订',
    '买', '取', '打电话', '签到', '记一笔',
  ];

  static int local(String title) {
    final t = title.trim();
    if (t.isEmpty) return 2;
    if (_small.any(t.contains)) return 1;
    var n = 2;
    if (_big.any(t.contains)) n = 3;
    if (t.length >= 18) n += 1; // 标题很长 → 体量更大
    return n.clamp(1, 4);
  }

  /// 从 AI 文本里抽第一个 1–4 的整数；抽不到/越界 → 本地兜底。
  static int parseOrLocal(String aiText, String title) {
    final m = RegExp(r'[1-4]').firstMatch(aiText);
    if (m == null) return local(title);
    return int.parse(m.group(0)!).clamp(1, 4);
  }
}
