import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:promptme/domain/sync/capture_message.dart';
import 'package:promptme/services/sync/desktop_capture_sender.dart';

void main() {
  test('发送器产出的负载，手机解析器能完整解回（契约往返）', () async {
    String? sentBody;
    Uri? sentUri;
    final client = MockClient((req) async {
      sentUri = req.url;
      sentBody = req.body;
      return http.Response('', 200);
    });
    final sender = DesktopCaptureSender(client: client);

    final ok = await sender.send(
      topic: 'promptme-abc',
      text: '桌面发来的想法',
      domain: '工作',
      toToday: true,
      id: 'd-1',
    );
    expect(ok, isTrue);
    expect(sentUri.toString(), 'https://ntfy.sh/promptme-abc');

    // 关键：手机侧解析器能从同一 body 还原出捕获
    final parsed = CaptureMessage.tryParsePayload(sentBody!);
    expect(parsed, isNotNull);
    expect(parsed!.id, 'd-1');
    expect(parsed.text, '桌面发来的想法');
    expect(parsed.domain, '工作');
    expect(parsed.toToday, isTrue);
  });

  test('空 topic / 空文本 → 不发送返回 false', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response('', 200);
    });
    final sender = DesktopCaptureSender(client: client);
    expect(await sender.send(topic: '', text: 'x'), isFalse);
    expect(await sender.send(topic: 't', text: '   '), isFalse);
    expect(calls, 0);
  });

  test('非 2xx → 返回 false', () async {
    final client = MockClient((req) async => http.Response('err', 500));
    final sender = DesktopCaptureSender(client: client);
    expect(await sender.send(topic: 't', text: 'x'), isFalse);
  });
}
