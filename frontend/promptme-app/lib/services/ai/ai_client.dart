import 'dart:convert';
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

  /// 统一的「给提示词、拿纯文本」。按 provider 组请求与解析响应。
  Future<String> _complete(String prompt) async {
    final isClaude = config.provider == AiProvider.claude;
    final headers = <String, String>{
      'content-type': 'application/json',
      if (isClaude) ...{
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      } else
        'authorization': 'Bearer ${config.apiKey}',
    };
    final body = isClaude
        ? {
            'model': config.effectiveModel,
            'max_tokens': 1024,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }
        : {
            'model': config.effectiveModel,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          };

    final resp = await _client.post(config.endpoint,
        headers: headers, body: jsonEncode(body));
    if (resp.statusCode != 200) {
      throw Exception('AI 调用失败 HTTP ${resp.statusCode}: ${resp.body}');
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (isClaude) {
      final content = json['content'] as List;
      return (content.first as Map<String, dynamic>)['text'] as String;
    } else {
      final choices = json['choices'] as List;
      return ((choices.first as Map<String, dynamic>)['message']
          as Map<String, dynamic>)['content'] as String;
    }
  }
}
