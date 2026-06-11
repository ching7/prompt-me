import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:promptme/features/settings/settings_screen.dart';
import 'package:promptme/state/integration_providers.dart';

void main() {
  testWidgets('AI 启用开关：默认关，点击后变开并持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pump();

    // 两个开关：AI（第一个）+ 桌面同步。这里验 AI。
    final sw = find.byType(Switch).first;
    expect(find.byType(Switch), findsNWidgets(2));
    expect(tester.widget<Switch>(sw).value, false); // 默认关

    await tester.tap(sw);
    await tester.pump();
    expect(tester.widget<Switch>(sw).value, true);
    expect(prefs.getBool('ai_enabled'), true); // 已持久化
  });
}
