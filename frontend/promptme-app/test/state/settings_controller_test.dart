import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:promptme/state/settings_controller.dart';

void main() {
  test('aiEnabled 默认 false、setAiEnabled 持久化并反映到 aiConfig', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsController(prefs);
    expect(s.aiEnabled, false);
    expect(s.aiConfig.enabled, false);

    await s.setAiEnabled(true);
    expect(s.aiEnabled, true);
    expect(s.aiConfig.enabled, true);
  });
}
