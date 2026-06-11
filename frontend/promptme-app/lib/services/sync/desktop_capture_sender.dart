import 'dart:convert';
import 'package:http/http.dart' as http;

/// 桌面端发送捕获到 ntfy（POST `https://ntfy.sh/<topic>`，body = 契约 JSON）。
/// 契约见 docs/api-spec/2026-06-11-ntfy-sync-contract.md。
class DesktopCaptureSender {
  DesktopCaptureSender({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  /// 发一条捕获。成功（HTTP 2xx）返回 true。[id] 不传则按时间戳生成（幂等键）。
  Future<bool> send({
    required String topic,
    required String text,
    String? domain,
    bool toToday = false,
    String? id,
    DateTime? now,
  }) async {
    final t = topic.trim();
    final body = text.trim();
    if (t.isEmpty || body.isEmpty) return false;
    final ts = now ?? DateTime.now();
    final payload = jsonEncode({
      'v': 1,
      'type': 'capture',
      'id': id ?? 'd-${ts.microsecondsSinceEpoch}',
      'text': body,
      if (domain != null && domain.trim().isNotEmpty) 'domain': domain.trim(),
      'dest': toToday ? 'today' : 'inbox',
      'ts': ts.millisecondsSinceEpoch ~/ 1000,
    });
    final resp = await _client.post(Uri.parse('https://ntfy.sh/$t'), body: payload);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}
