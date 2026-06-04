import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/services/ai/ai_client.dart';
import 'package:promptme/services/ai/ai_config.dart';

void main() {
  test('prioritize parses Claude response', () async {
    final client = MockClient((req) async {
      expect(req.headers['x-api-key'], 'sk-test');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'content': [
            {'type': 'text', 'text': '{"suggestions":[{"task":"项目周报","quadrant":"重要紧急","reason":"今天deadline"}],"todayFocus":["项目周报"]}'}
          ]
        })),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final ai = AiClient(
      config: const AiConfig(provider: AiProvider.claude, apiKey: 'sk-test'),
      client: client,
    );
    final r = await ai.prioritize(taskTitles: ['项目周报'], todayEvents: []);
    expect(r.suggestions.single.quadrant, Quadrant.importantUrgent);
  });

  test('downgrade returns one-line micro from OpenAI-compatible response', () async {
    final client = MockClient((req) async {
      expect(req.headers['authorization'], 'Bearer sk-x');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {'message': {'content': '只打开周报文档，写一句话。'}}
          ]
        })),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final ai = AiClient(
      config: const AiConfig(
          provider: AiProvider.openaiCompatible,
          apiKey: 'sk-x',
          baseUrl: 'https://api.deepseek.com'),
      client: client,
    );
    final micro = await ai.downgrade(
        taskTitle: '项目周报', reason: FailureReason.tired, level: 1);
    expect(micro.trim(), '只打开周报文档，写一句话。');
  });
}
