import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/services/ai/ai_config.dart';

void main() {
  test('isActive = 开启 且 有 key', () {
    expect(const AiConfig(apiKey: 'sk', enabled: true).isActive, true);
    expect(const AiConfig(apiKey: 'sk', enabled: false).isActive, false); // 关掉
    expect(const AiConfig(apiKey: '', enabled: true).isActive, false); // 没 key
  });

  test('enabled 默认 false', () {
    expect(const AiConfig(apiKey: 'sk').enabled, false);
  });
}
