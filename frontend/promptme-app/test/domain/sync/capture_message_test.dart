import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/sync/capture_message.dart';

String ntfyLine(Map<String, dynamic> payload, {String event = 'message'}) =>
    jsonEncode({'event': event, 'message': jsonEncode(payload)});

void main() {
  group('tryParsePayload', () {
    test('合法 capture 负载', () {
      final m = CaptureMessage.tryParsePayload(
          '{"v":1,"type":"capture","id":"a1","text":"写周报","domain":"工作","dest":"today"}');
      expect(m, isNotNull);
      expect(m!.id, 'a1');
      expect(m.text, '写周报');
      expect(m.domain, '工作');
      expect(m.toToday, isTrue);
    });

    test('dest 缺省 → 收件箱（toToday=false）；domain 空 → null', () {
      final m = CaptureMessage.tryParsePayload(
          '{"v":1,"type":"capture","id":"a2","text":"想法","domain":""}');
      expect(m!.toToday, isFalse);
      expect(m.domain, isNull);
    });

    test('版本不符 / 类型不符 / 缺必填 / 非法 JSON → null', () {
      expect(
          CaptureMessage.tryParsePayload(
              '{"v":2,"type":"capture","id":"x","text":"a"}'),
          isNull);
      expect(
          CaptureMessage.tryParsePayload(
              '{"v":1,"type":"other","id":"x","text":"a"}'),
          isNull);
      expect(
          CaptureMessage.tryParsePayload('{"v":1,"type":"capture","text":"a"}'),
          isNull); // 缺 id
      expect(
          CaptureMessage.tryParsePayload(
              '{"v":1,"type":"capture","id":"x","text":"  "}'),
          isNull); // 空 text
      expect(CaptureMessage.tryParsePayload('不是 json'), isNull);
    });
  });

  group('tryParseNtfyLine', () {
    test('message 事件 → 解析内层负载', () {
      final line = ntfyLine(
          {'v': 1, 'type': 'capture', 'id': 'b1', 'text': '点子'});
      final m = CaptureMessage.tryParseNtfyLine(line);
      expect(m!.id, 'b1');
      expect(m.text, '点子');
    });

    test('open/keepalive 事件 → null', () {
      expect(CaptureMessage.tryParseNtfyLine('{"event":"open"}'), isNull);
      expect(CaptureMessage.tryParseNtfyLine('{"event":"keepalive"}'), isNull);
    });

    test('空行 / 非法行 → null', () {
      expect(CaptureMessage.tryParseNtfyLine(''), isNull);
      expect(CaptureMessage.tryParseNtfyLine('   '), isNull);
      expect(CaptureMessage.tryParseNtfyLine('garbage'), isNull);
    });
  });
}
