/// 领域标签：默认四个 + 自定义（任意其它字符串）。`null`/空 = 未分类。
const List<String> kDefaultDomains = ['工作', '自媒体', '学习', '家庭'];

bool isCustomDomain(String? label) {
  if (label == null) return false;
  final s = label.trim();
  return s.isNotEmpty && !kDefaultDomains.contains(s);
}
