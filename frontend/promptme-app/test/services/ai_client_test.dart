import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/services/ai/ai_cache.dart';
import 'package:promptme/services/ai/ai_client.dart';
import 'package:promptme/services/ai/ai_config.dart';

void main() {
  test('prioritize parses an OpenAI-compatible response', () async {
    final client = MockClient((req) async {
      expect(req.headers['authorization'], 'Bearer sk-test');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {
              'message': {
                'content':
                    '{"suggestions":[{"task":"项目周报","quadrant":"重要紧急","reason":"今天deadline"}],"todayFocus":["项目周报"]}'
              }
            }
          ]
        })),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final ai = AiClient(
      config: const AiConfig(
          apiKey: 'sk-test', baseUrl: 'https://api.deepseek.com'),
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
          apiKey: 'sk-x', baseUrl: 'https://api.deepseek.com'),
      client: client,
    );
    final micro = await ai.downgrade(
        taskTitle: '项目周报', reason: FailureReason.tired, level: 1);
    expect(micro.trim(), '只打开周报文档，写一句话。');
  });

  test('estimateTomato 从文本抽出 1–4 整数', () async {
    final client = MockClient((req) async => http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {'message': {'content': '这个任务大概需要 3 个番茄。'}}
            ]
          })),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final ai = AiClient(
      config: const AiConfig(apiKey: 'k', baseUrl: 'https://x.com'),
      client: client,
    );
    expect(await ai.estimateTomato(taskTitle: '写周报'), 3);
  });

  test('AiCache 命中：相同请求只打一次网络', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
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
      config: const AiConfig(apiKey: 'k', baseUrl: 'https://x.com'),
      client: client,
      cache: AiCache(),
    );
    final a = await ai.downgrade(
        taskTitle: '周报', reason: FailureReason.tired, level: 1);
    final b = await ai.downgrade(
        taskTitle: '周报', reason: FailureReason.tired, level: 1);
    expect(a, b);
    expect(calls, 1); // 第二次命中缓存，不再打网络
  });

  test('testConnection 不走缓存（每次真打）', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {'message': {'content': 'pong'}}
          ]
        })),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final ai = AiClient(
      config: const AiConfig(apiKey: 'k', baseUrl: 'https://x.com'),
      client: client,
      cache: AiCache(),
    );
    await ai.testConnection();
    await ai.testConnection();
    expect(calls, 2); // ping 不缓存
  });

  test('endpoint normalizes a baseUrl that already ends in /v1', () {
    const c = AiConfig(
        apiKey: 'k', baseUrl: 'https://token-plan-cn.xiaomimimo.com/v1');
    expect(c.endpoint.toString(),
        'https://token-plan-cn.xiaomimimo.com/v1/chat/completions');
  });

  test('endpoint keeps a /v2 version segment (讯飞 MaaS)', () {
    const c = AiConfig(
        apiKey: 'k', baseUrl: 'https://maas-api.cn-huabei-1.xf-yun.com/v2');
    expect(c.endpoint.toString(),
        'https://maas-api.cn-huabei-1.xf-yun.com/v2/chat/completions');
  });

  test('endpoint defaults a bare host to /v1', () {
    const c = AiConfig(
        apiKey: 'k', baseUrl: 'https://maas-api.cn-huabei-1.xf-yun.com');
    expect(c.endpoint.toString(),
        'https://maas-api.cn-huabei-1.xf-yun.com/v1/chat/completions');
  });

  test('endpoint trims a trailing slash', () {
    const c = AiConfig(apiKey: 'k', baseUrl: 'https://x.com/');
    expect(c.endpoint.toString(), 'https://x.com/v1/chat/completions');
  });

  test('custom model overrides the default', () {
    const c = AiConfig(apiKey: 'k', model: 'mimo-7b');
    expect(c.effectiveModel, 'mimo-7b');
  });

  test('blank model falls back to deepseek-chat', () {
    const c = AiConfig(apiKey: 'k', model: '  ');
    expect(c.effectiveModel, 'deepseek-chat');
  });
}
