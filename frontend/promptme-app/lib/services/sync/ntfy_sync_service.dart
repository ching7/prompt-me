// ignore_for_file: prefer_initializing_formals  (db/connector/reconnectDelay 是公开命名参)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../data/database.dart';
import '../../domain/sync/capture_message.dart';

/// 行式流连接器：给 topic、返回一条条文本行（ntfy `/json` 每行一个事件）。
/// 默认走 ntfy.sh HTTP 长连接；测试可注入假流。
typedef LineConnector = Stream<String> Function(String topic);

/// ntfy 单向同步（桌面 → 手机）：订阅 topic，把捕获负载幂等落库。
/// MVP = App 运行时同步；后台保活后置（见契约 §6）。
class NtfySyncService {
  NtfySyncService({
    required AppDatabase db,
    http.Client? client,
    LineConnector? connector,
    Duration reconnectDelay = const Duration(seconds: 3),
  })  : _db = db,
        _client = client ?? http.Client(),
        _connector = connector,
        _reconnectDelay = reconnectDelay;

  final AppDatabase _db;
  final http.Client _client;
  final LineConnector? _connector;
  final Duration _reconnectDelay;

  bool _running = false;
  String? _topic;
  StreamSubscription<String>? _sub;
  // 串行处理链：保证逐条处理（避免同 id 并发各自查「不存在」都插入→破坏幂等）。
  Future<void> _chain = Future<void>.value();
  // 已处理到的 ntfy 事件时间（秒）。断线重连/手动 resync 用 ?since= 续传，配合 syncId 幂等不重复。
  int? _sinceTimeSec;

  bool get isRunning => _running;
  String? get topic => _topic;

  /// 开始订阅某 topic（空/重复则忽略/重启）。新订阅不回放历史（避免复活已删项）。
  Future<void> start(String topic) async {
    final t = topic.trim();
    if (t.isEmpty) return;
    if (_running && _topic == t) return; // 已在订阅同一 topic
    await stop();
    _running = true;
    _topic = t;
    _sinceTimeSec = null; // 冷启动只收新消息
    debugPrint('[SYNC] 开始订阅 ntfy topic=$t');
    _listen();
  }

  Future<void> stop() async {
    _running = false;
    await _sub?.cancel();
    _sub = null;
  }

  /// 手动强制重连续传（下拉刷新兜底）：从上次进度 since 重放，幂等去重。
  Future<void> resync() async {
    if (!_running || _topic == null) return;
    await _sub?.cancel();
    _sub = null;
    debugPrint('[SYNC] 手动 resync（since=$_sinceTimeSec）');
    _listen();
  }

  void _listen() {
    final t = _topic;
    if (!_running || t == null) return;
    final stream = (_connector ?? _defaultConnect)(t);
    _sub = stream.listen(
      (line) {
        // 串到链尾，逐条 await，保证幂等不被并发破坏。
        _chain = _chain.then((_) => _running ? _handleLine(line) : null);
      },
      onError: (e) {
        debugPrint('[SYNC] 流出错：$e');
        _scheduleReconnect();
      },
      onDone: () {
        debugPrint('[SYNC] 流结束（服务器关闭）');
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (!_running) return;
    Future<void>.delayed(_reconnectDelay, () {
      if (_running) _listen();
    });
  }

  Future<void> _handleLine(String line) async {
    final l = line.trim();
    if (l.isEmpty) return;
    final Object? outer = _tryJson(l);
    if (outer is! Map) return;
    final time = outer['time'];
    if (time is int) _sinceTimeSec = time; // 记进度，重连/resync 用 since 续传
    if (outer['event'] != 'message') return; // open/keepalive 等忽略
    final body = outer['message'];
    if (body is! String) return;
    final msg = CaptureMessage.tryParsePayload(body);
    if (msg == null) return;
    final inserted = await _db.taskDao.insertSyncedCaptureIfNew(
      syncId: msg.id,
      title: msg.text,
      domain: msg.domain,
      toToday: msg.toToday,
    );
    debugPrint(inserted
        ? '[SYNC] 落库捕获 id=${msg.id} → ${msg.toToday ? '今日' : '收件箱'}'
        : '[SYNC] 幂等跳过 id=${msg.id}（已存在）');
  }

  static Object? _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  /// 默认连接：ntfy.sh `/<topic>/json` 行式流；有进度则 `?since=` 续传。
  Stream<String> _defaultConnect(String topic) async* {
    final since = _sinceTimeSec;
    final uri = Uri.parse(
        'https://ntfy.sh/$topic/json${since != null ? '?since=$since' : ''}');
    final resp = await _client.send(http.Request('GET', uri));
    yield* resp.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}
