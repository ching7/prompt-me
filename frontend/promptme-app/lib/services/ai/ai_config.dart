/// 只兼容 OpenAI 协议（`/chat/completions`）。讯飞 MaaS / DeepSeek / Qwen 等皆属此类。
class AiConfig {
  final String apiKey;
  final String? baseUrl;
  final String? model;

  const AiConfig({
    required this.apiKey,
    this.baseUrl,
    this.model,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  String get effectiveModel =>
      (model?.trim().isNotEmpty ?? false) ? model!.trim() : 'deepseek-chat';

  /// 由用户填的 Base URL 拼出 chat/completions 端点，兼容讯飞 MaaS 的多种写法：
  /// - 已写到 `/chat/completions`：原样用；
  /// - 已带版本段（`/v1`、`/v2`…）：仅补 `/chat/completions`（讯飞 `/v1`、`/v2` 都支持）；
  /// - 只到域名：默认补 `/v1/chat/completions`。
  Uri get endpoint {
    final b = _normalizedBase;
    if (b.endsWith('/chat/completions')) return Uri.parse(b);
    if (RegExp(r'/v\d+$').hasMatch(b)) return Uri.parse('$b/chat/completions');
    return Uri.parse('$b/v1/chat/completions');
  }

  /// 去尾斜杠；留空时用 OpenAI 官方域名兜底。
  String get _normalizedBase {
    final b = (baseUrl?.trim().isNotEmpty ?? false)
        ? baseUrl!.trim()
        : 'https://api.openai.com';
    return b.replaceAll(RegExp(r'/+$'), '');
  }
}
