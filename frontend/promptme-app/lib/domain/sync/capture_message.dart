import 'dart:convert';

/// 桌面捕获负载（ntfy 消息正文里的 JSON）。纯数据 + 容错解析。
/// 契约见 docs/api-spec/2026-06-11-ntfy-sync-contract.md。
class CaptureMessage {
  const CaptureMessage({
    required this.id,
    required this.text,
    this.domain,
    this.toToday = false,
  });

  final String id; // 幂等键
  final String text;
  final String? domain;
  final bool toToday; // dest == "today"

  /// 解析**一行 ntfy 事件 JSON**（`/json` 订阅流）。
  /// 非 message 事件 / 缺字段 / 版本不符 → null（静默忽略，不抛）。
  static CaptureMessage? tryParseNtfyLine(String line) {
    final l = line.trim();
    if (l.isEmpty) return null;
    final Object? decoded = _tryJson(l);
    if (decoded is! Map) return null;
    if (decoded['event'] != 'message') return null; // open/keepalive 等忽略
    final msg = decoded['message'];
    if (msg is! String) return null;
    return tryParsePayload(msg);
  }

  /// 解析内层捕获负载 JSON 字符串。
  static CaptureMessage? tryParsePayload(String raw) {
    final Object? decoded = _tryJson(raw);
    if (decoded is! Map) return null;
    if (decoded['v'] != 1) return null;
    if (decoded['type'] != 'capture') return null;
    final id = (decoded['id'] ?? '').toString().trim();
    final text = (decoded['text'] ?? '').toString().trim();
    if (id.isEmpty || text.isEmpty) return null; // 必填缺失
    final domainRaw = (decoded['domain'] ?? '').toString().trim();
    final dest = (decoded['dest'] ?? 'inbox').toString();
    return CaptureMessage(
      id: id,
      text: text,
      domain: domainRaw.isEmpty ? null : domainRaw,
      toToday: dest == 'today',
    );
  }

  static Object? _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
}
