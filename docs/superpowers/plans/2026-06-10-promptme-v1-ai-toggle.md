# PromptMe v1 · AI 总开关 + 配置实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development / executing-plans。Steps 用 checkbox 跟踪。

**Goal:** 给 AI 一个**显式总开关**(默认关)。开 → 用已配置的 key 跑 AI(降级等);关 → **保持现状**(本地兜底,绝不发网络请求)。配置(key/Base URL/模型)沿用既有设置屏,新增开关 + 状态提示。

**为什么:** 现状门控是隐式的 `isConfigured`(有 key 即调 AI)。作者要能「配了 key 也能一键关掉、回到纯本地行为」,且作为后续 MAP 诊断 / 复盘等 AI 功能统一的开关闸。

**Architecture（最小改动,复用既有 AI 地基）:**
- `AiConfig` 加 `final bool enabled`(默认 `false`)+ `bool get isActive => enabled && isConfigured`。**所有 AI 调用点门控由 `isConfigured` 换成 `isActive`**(当前仅 `TodayController.tooHard` 一处;后续 MAP/复盘也查 `isActive`)。`testConnection`/设置屏「测试连接」**不**受开关影响(测 key 用)。
- `SettingsController` 加 `bool get aiEnabled`(prefs `ai_enabled`,默认 false)、`setAiEnabled(bool)`;`aiConfig` getter 带上 `enabled: aiEnabled`。
- `settings_screen` AI 卡顶部加「启用 AI」`Switch` + 一行说明(关 = 本地兜底);切换即存 + `ref.invalidate(aiClientProvider)`。
- 默认关:既有/新装在未开开关前,行为与「无 AI」完全一致。

**范围边界（不做）:** 不动 AI client 的 HTTP/解析逻辑;不加新 AI 功能(MAP/复盘另计划);不做按功能粒度的细分开关(就一个总闸);key 仍明文存 prefs(安全加固后续再说)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;shared_preferences 2.5;flutter_test。

**工程根:** `frontend/promptme-app/`。分支 `feat/v1-ai-toggle`。前置:1.1–1.7 已在 master。

**⚠️ 跑测试/analyze 必带前缀**(同其它计划,国内代理坑);**别 `flutter clean`**。

---

### Task 1: AiConfig.isActive + SettingsController.aiEnabled + 门控切换

**Files:**
- Modify: `lib/services/ai/ai_config.dart`、`lib/state/settings_controller.dart`、`lib/state/today_controller.dart`
- Test: `test/services/ai/ai_config_test.dart`(新)、`test/state/settings_controller_test.dart`(新)、`test/state/today_controller_test.dart`(追加)

- [ ] **Step 1: 写失败测试**

`test/services/ai/ai_config_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/services/ai/ai_config.dart';

void main() {
  test('isActive = 开启 且 有 key', () {
    expect(const AiConfig(apiKey: 'sk', enabled: true).isActive, true);
    expect(const AiConfig(apiKey: 'sk', enabled: false).isActive, false); // 关掉
    expect(const AiConfig(apiKey: '', enabled: true).isActive, false);    // 没 key
  });
  test('enabled 默认 false', () {
    expect(const AiConfig(apiKey: 'sk').enabled, false);
  });
}
```

`test/state/settings_controller_test.dart`:
```dart
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
```

`test/state/today_controller_test.dart` 追加(AI 配了 key 但开关关 → 仍本地兜底):
```dart
    test('AI 关闭时 tooHard 走本地兜底（即便有 key）', () async {
      SharedPreferences.setMockInitialValues(
          {'ai_key': 'sk-xxx', 'ai_enabled': false});
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c2.dispose);
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
          title: '完成项目周报',
          quadrant: Quadrant.importantUrgent,
          source: TaskSource.manual));
      final micro =
          await c2.read(todayControllerProvider).tooHard(id, FailureReason.tired);
      expect(micro, contains('完成项目周报')); // 本地兜底文案，未发网络
    });
```
（顶部补 `import 'package:shared_preferences/shared_preferences.dart';`、`import 'package:promptme/state/integration_providers.dart';`。）

- [ ] **Step 2: 跑测试确认失败** — `enabled`/`isActive`/`aiEnabled`/`setAiEnabled` 不存在。

- [ ] **Step 3: 实现**
  - `ai_config.dart`:加 `final bool enabled;`、构造 `this.enabled = false`、`bool get isActive => enabled && isConfigured;`。
  - `settings_controller.dart`:加 `static const _kEnabled='ai_enabled';`、`bool get aiEnabled => _prefs.getBool(_kEnabled) ?? false;`、`Future<void> setAiEnabled(bool v)=>_prefs.setBool(_kEnabled,v);`;`aiConfig` getter 加 `enabled: aiEnabled,`。
  - `today_controller.dart` 的 `tooHard`:`ai.config.isConfigured` → `ai.config.isActive`。

- [ ] **Step 4: 跑测试确认通过** + `flutter analyze lib`。

- [ ] **Step 5: 提交** `feat(ai): AiConfig.enabled/isActive + SettingsController.aiEnabled + tooHard 门控走 isActive`

---

### Task 2: 设置屏「启用 AI」开关

**Files:** Modify `lib/features/settings/settings_screen.dart`;Test `test/features/settings/settings_screen_test.dart`(新或追加)

- [ ] **Step 1: 写失败测试** — pump `SettingsScreen`(override `sharedPrefsProvider` 用 mock prefs),断言找到一个 `Switch`、初始 `value=false`;tap 后 `settingsProvider.aiEnabled` 变 true。

- [ ] **Step 2: 跑测试确认失败**。

- [ ] **Step 3: 实现** — state 加 `late bool _aiEnabled = ref.read(settingsProvider).aiEnabled;`;`_aiCard` 顶部加 `SwitchListTile`(标题「启用 AI」,副标题「关闭后所有 AI 功能走本地兜底」),`onChanged: _toggleAi`;
```dart
  Future<void> _toggleAi(bool v) async {
    setState(() => _aiEnabled = v);
    await ref.read(settingsProvider).setAiEnabled(v);
    ref.invalidate(aiClientProvider);
  }
```

- [ ] **Step 4: 全量 test + analyze + 提交** `feat(settings): AI 卡片加启用开关(默认关,本地兜底说明)`

---

## 完成判据
- `flutter analyze` 无 issue;`flutter test` 全绿。
- 设置屏有「启用 AI」开关,默认关;关时 `tooHard` 即便配了 key 也走本地兜底,无网络请求;开 + 有 key 才真正调 AI。
- 「测试连接」不受开关影响。

## 衔接
后续 MAP 诊断标签 / 复盘 AI 调用点统一查 `aiConfig.isActive`。
