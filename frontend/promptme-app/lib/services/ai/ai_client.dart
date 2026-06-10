import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../domain/ai/ai_models.dart';
import '../../domain/ai/ai_prompts.dart';
import '../../domain/ai/ai_response_parser.dart';
import '../../domain/enums.dart';
import '../../domain/fogg/downgrade.dart';
import 'ai_config.dart';

class AiClient {
  AiClient({required this.config, http.Client? client})
      : _client = client ?? http.Client();
  final AiConfig config;
  final http.Client _client;

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
    return line.isEmpty ? Downgrade.localFallback(taskTitle, level) : line;
  }

  /// 设置页「测试连接」用：发一条最小请求，成功返回 null，失败返回错误说明。
  Future<String?> testConnection() async {
    try {
      await _complete('ping');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 统一的「给提示词、拿纯文本」，走 OpenAI 协议 `/chat/completions`。
  Future<String> _complete(String prompt) async {
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
    return ((choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>)['content'] as String;
  }
}
