import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../domain/ai/ai_models.dart';
import '../../domain/ai/ai_prompts.dart';
import '../../domain/ai/ai_response_parser.dart';
import '../../domain/enums.dart';
import '../../domain/fogg/downgrade.dart';
import '../../domain/fogg/tomato_estimator.dart';
import 'ai_cache.dart';
import 'ai_config.dart';

class AiClient {
  AiClient({required this.config, http.Client? client, AiCache? cache})
      : _client = client ?? http.Client(),
        // ignore: prefer_initializing_formals  (cache 是公开命名参，不能写成 this._cache)
        _cache = cache;
  final AiConfig config;
  final http.Client _client;
  final AiCache? _cache;

  Future<PrioritizeResult> prioritize({
    required List<String> taskTitles,
    required List<String> todayEvents,
  }) async {
    final text = await _complete(
        AiPrompts.prioritize(taskTitles: taskTitles, todayEvents: todayEvents));
    return AiResponseParser.parsePrioritize(text);
  }

  Future<List<ReviewItem>> review(List<String> overdueDescriptions) async {
    final text =
        await _complete(AiPrompts.review(overdueDescriptions: overdueDescriptions));
    return AiResponseParser.parseReview(text);
  }

  Future<String> downgrade({
    required String taskTitle,
    required FailureReason reason,
    required int level,
  }) async {
    final text = await _complete(Downgrade.buildPrompt(
        taskTitle: taskTitle, reason: reason, level: level));
    final line = text.trim().split('\n').first.trim();
    return line.isEmpty
        ? Downgrade.localFallback(taskTitle, reason, level)
        : line;
  }

  /// 预估番茄数（1–4）。AI 解析失败/异常 → 本地启发式兜底，绝不抛给 UI。
  Future<int> estimateTomato({required String taskTitle}) async {
    try {
      final text = await _complete(AiPrompts.estimateTomato(taskTitle));
      return TomatoEstimator.parseOrLocal(text, taskTitle);
    } catch (_) {
      return TomatoEstimator.local(taskTitle);
    }
  }

  /// 设置页「测试连接」用：发一条最小请求，成功返回 null，失败返回错误说明。
  /// 不走缓存（每次都要真打一发，验证凭据/连通）。
  Future<String?> testConnection() async {
    try {
      await _complete('ping', useCache: false);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 统一的「给提示词、拿纯文本」，走 OpenAI 协议 `/chat/completions`。
  /// 命中缓存即省一次请求（按 prompt 文本去重）。
  Future<String> _complete(String prompt, {bool useCache = true}) async {
    if (useCache) {
      final cached = _cache?.get(prompt);
      if (cached != null) {
        debugPrint('[AI] 命中缓存 → 省一次请求');
        return cached;
      }
    }
    final headers = <String, String>{
      'content-type': 'application/json',
      'authorization': 'Bearer ${config.apiKey}',
    };
    final body = {
      'model': config.effectiveModel,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    };

    debugPrint('[AI] POST ${config.endpoint} model=${config.effectiveModel}');
    final resp = await _client.post(config.endpoint,
        headers: headers, body: jsonEncode(body));
    debugPrint('[AI] ← HTTP ${resp.statusCode}');
    if (resp.statusCode != 200) {
      throw Exception('AI 调用失败 HTTP ${resp.statusCode}: ${resp.body}');
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    final content = ((choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>)['content'] as String;
    if (useCache) _cache?.put(prompt, content);
    return content;
  }
}
