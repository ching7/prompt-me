# PromptMe 第一波 · 计划③ 集成（订阅 / 飞书导入 / AI / 通知 / 设置）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把今日屏从「只有手动任务」升级为「自动有数据 + AI 教练 + 锁屏提示」：苹果日历 webcal 订阅、飞书 Markdown 粘贴导入、AI（整理今日 / 复盘未完成 / 无底线降级实网化）、本地通知（定时 + 常驻『今日·重要紧急』+ 降级后刷新微习惯到锁屏）、设置页。完成后即第一波全部就绪。

**Architecture:** 纯逻辑（计划①）+ 数据/控制（计划①②）已就位。本计划只加「外部世界的边」：HTTP（订阅、AI）、平台通知。所有可注入 `http.Client` 的服务都用假 client 做 TDD；通知与设置 UI 在真机走查。AI key/provider/订阅链接用 `shared_preferences` 持久化。

**Tech Stack:** Flutter · http · shared_preferences · flutter_local_notifications · timezone · Riverpod · flutter_test

**前置：** 计划①② 完成，`flutter test` 全绿，今日屏可手动新增/打卡/降级。

---

## File Structure

```
lib/
  services/
    calendar_subscription_service.dart     # GET ics -> IcsParser -> CalendarDao.replaceEvents
    ai/
      ai_config.dart                        # AiProvider 枚举 + 端点/模型 + 设置键
      ai_client.dart                        # BYO key HTTP（可注入 http.Client）
    notification_service.dart               # 定时 + 常驻 + 微习惯刷新
  domain/import/
    feishu_importer.dart                    # 解析树 -> Task 行（落库）
  state/
    settings_controller.dart                # shared_preferences 读写
    integration_providers.dart              # aiClientProvider / subscriptionServiceProvider / notificationServiceProvider
  features/
    settings/settings_screen.dart
    settings/feishu_import_sheet.dart
    today/widgets/ai_panel.dart             # 整理今日 / 复盘结果
test/
  services/calendar_subscription_service_test.dart
  services/ai_client_test.dart
  domain/import/feishu_importer_test.dart
```

---

### Task 1: 日历订阅服务

**Files:**
- Create: `lib/services/calendar_subscription_service.dart`
- Test: `test/services/calendar_subscription_service_test.dart`

- [ ] **Step 1: 写失败测试（注入假 http.Client）**

`test/services/calendar_subscription_service_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/services/calendar_subscription_service.dart';

const _ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:e1
SUMMARY:周报
DTSTART:20260603T020000Z
DTEND:20260603T033000Z
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('fetch parses ICS and replaces events for a subscription', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));

    final client = MockClient((req) async => http.Response(_ics, 200));
    final svc = CalendarSubscriptionService(db, client: client);

    await svc.refresh(subId, 'https://x/ics');

    final events = await db.calendarDao.eventsForDate(DateTime(2026, 6, 3));
    expect(events.single.title, '周报');
    final sub = (await db.calendarDao.subscriptionsList()).single;
    expect(sub.lastFetchedAt, isNotNull);
  });

  test('non-200 throws and does not wipe existing events', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));
    final ok = MockClient((req) async => http.Response(_ics, 200));
    await CalendarSubscriptionService(db, client: ok).refresh(subId, 'https://x/ics');

    final bad = MockClient((req) async => http.Response('err', 500));
    await expectLater(
      CalendarSubscriptionService(db, client: bad).refresh(subId, 'https://x/ics'),
      throwsA(isA<Exception>()),
    );
    // 旧数据仍在
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 1);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/services/calendar_subscription_service_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现**

`lib/services/calendar_subscription_service.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import '../data/database.dart';
import '../domain/parsing/ics_parser.dart';

class CalendarSubscriptionService {
  CalendarSubscriptionService(this.db, {http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase db;
  final http.Client _client;

  /// 拉取一个 webcal/已发布 ICS 链接并替换该订阅的全部事件。
  /// 失败时抛异常且不动旧数据（先解析成功再写库）。
  Future<void> refresh(int subscriptionId, String url) async {
    final uri = Uri.parse(url.replaceFirst('webcal://', 'https://'));
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('订阅拉取失败 HTTP ${resp.statusCode}');
    }
    final parsed = IcsParser.parse(resp.body);
    final companions = parsed
        .map((e) => CalendarEventsCompanion.insert(
              subscriptionId: subscriptionId,
              uid: e.uid,
              title: e.title,
              start: e.start,
              end: Value(e.end),
              allDay: Value(e.allDay),
            ))
        .toList();
    await db.calendarDao.replaceEvents(subscriptionId, companions);
    await (db.update(db.subscriptions)
          ..where((s) => s.id.equals(subscriptionId)))
        .write(SubscriptionsCompanion(lastFetchedAt: Value(DateTime.now())));
  }

  Future<void> refreshAll() async {
    for (final sub in await db.calendarDao.subscriptionsList()) {
      try {
        await refresh(sub.id, sub.url);
      } catch (_) {
        // 单个失败不影响其它；UI 层另行提示
      }
    }
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/services/calendar_subscription_service_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/calendar_subscription_service.dart test/services/calendar_subscription_service_test.dart
git commit -m "feat: calendar subscription service (fetch ICS -> replace events)"
```

---

### Task 2: 飞书导入

**Files:**
- Create: `lib/domain/import/feishu_importer.dart`
- Test: `test/domain/import/feishu_importer_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/import/feishu_importer_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/import/feishu_importer.dart';

const _md = '''
# 0603
## 重要紧急
- [ ] 整理广西农信问题
  - [ ] 智算定制功能查看与了解
## 重要非紧急
- [x] 郑州银行进度跟踪
''';

void main() {
  test('imports tasks for a target date with quadrant, source, parent links', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final count = await FeishuImporter(db)
        .import(_md, targetDate: DateTime(2026, 6, 3));
    expect(count, 3);

    final rows = await db.taskDao.tasksForDate(DateTime(2026, 6, 3));
    final parent = rows.firstWhere((t) => t.title == '整理广西农信问题');
    expect(parent.quadrant, Quadrant.importantUrgent);
    expect(parent.source, TaskSource.feishu);

    final child = rows.firstWhere((t) => t.title == '智算定制功能查看与了解');
    expect(child.parentTaskId, parent.id);

    final done = rows.firstWhere((t) => t.title == '郑州银行进度跟踪');
    expect(done.status, TaskStatus.done);
    expect(done.quadrant, Quadrant.importantNotUrgent);
  });

  test('only imports the section matching targetDate', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const md = '# 0603\n## 重要紧急\n- [ ] A\n# 0602\n## 重要紧急\n- [ ] B';
    await FeishuImporter(db).import(md, targetDate: DateTime(2026, 6, 3));
    final rows = await db.taskDao.tasksForDate(DateTime(2026, 6, 3));
    expect(rows.map((t) => t.title), ['A']);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/import/feishu_importer_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现**

`lib/domain/import/feishu_importer.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import '../../data/database.dart';
import '../enums.dart';
import '../parsing/feishu_markdown_parser.dart';
import '../parsing/parsed_task.dart';

class FeishuImporter {
  FeishuImporter(this.db);
  final AppDatabase db;

  /// 解析飞书 Markdown，导入 [targetDate] 当天的任务（含嵌套），返回导入条数。
  Future<int> import(String markdown, {required DateTime targetDate}) async {
    final day = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final roots = FeishuMarkdownParser.parse(markdown, year: day.year)
        .where((t) => t.date == null || _sameDay(t.date!, day))
        .toList();

    var count = 0;
    Future<void> insertTree(ParsedTask node, int? parentId) async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
        title: node.title,
        quadrant: node.quadrant,
        source: TaskSource.feishu,
        scheduledDate: Value(day),
        firstScheduledDate: Value(day),
        parentTaskId: Value(parentId),
        status: Value(node.done ? TaskStatus.done : TaskStatus.pending),
        completedAt: Value(node.done ? day : null),
      ));
      count++;
      for (final child in node.children) {
        await insertTree(child, id);
      }
    }

    for (final root in roots) {
      await insertTree(root, null);
    }
    return count;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/domain/import/feishu_importer_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/import/feishu_importer.dart test/domain/import/feishu_importer_test.dart
git commit -m "feat: feishu importer (parsed tree -> task rows for target date)"
```

---

### Task 3: AI 客户端（BYO key）

**Files:**
- Create: `lib/services/ai/ai_config.dart`
- Create: `lib/services/ai/ai_client.dart`
- Test: `test/services/ai_client_test.dart`

- [ ] **Step 1: 写失败测试（假 client，覆盖 Claude 与 OpenAI 兼容）**

`test/services/ai_client_test.dart`:
```dart
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
      return http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': '{"suggestions":[{"task":"农信问题","quadrant":"重要紧急","reason":"今天deadline"}],"todayFocus":["农信问题"]}'}
          ]
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final ai = AiClient(
      config: const AiConfig(provider: AiProvider.claude, apiKey: 'sk-test'),
      client: client,
    );
    final r = await ai.prioritize(taskTitles: ['农信问题'], todayEvents: []);
    expect(r.suggestions.single.quadrant, Quadrant.importantUrgent);
  });

  test('downgrade returns one-line micro from OpenAI-compatible response', () async {
    final client = MockClient((req) async {
      expect(req.headers['authorization'], 'Bearer sk-x');
      return http.Response(
        utf8.encode(jsonEncode({
          'choices': [
            {'message': {'content': '只打开农信问题清单，写一句话。'}}
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
        taskTitle: '农信问题', reason: FailureReason.tired, level: 1);
    expect(micro.trim(), '只打开农信问题清单，写一句话。');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/services/ai_client_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现 AiConfig**

`lib/services/ai/ai_config.dart`:
```dart
enum AiProvider { claude, openaiCompatible }

class AiConfig {
  final AiProvider provider;
  final String apiKey;
  final String? baseUrl; // openaiCompatible 用；claude 固定
  final String? model;

  const AiConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.model,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  String get effectiveModel =>
      model ??
      switch (provider) {
        AiProvider.claude => 'claude-sonnet-4-6',
        AiProvider.openaiCompatible => 'deepseek-chat',
      };

  Uri get endpoint => switch (provider) {
        AiProvider.claude => Uri.parse('https://api.anthropic.com/v1/messages'),
        AiProvider.openaiCompatible =>
          Uri.parse('${baseUrl ?? 'https://api.openai.com'}/v1/chat/completions'),
      };
}
```

- [ ] **Step 4: 实现 AiClient**

`lib/services/ai/ai_client.dart`:
```dart
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
```

- [ ] **Step 5: 运行确认通过**

Run: `flutter test test/services/ai_client_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add lib/services/ai/ test/services/ai_client_test.dart
git commit -m "feat: AI client (BYO key, Claude + OpenAI-compatible)"
```

---

### Task 4: 设置持久化 + 集成 providers

**Files:**
- Create: `lib/state/settings_controller.dart`
- Create: `lib/state/integration_providers.dart`

- [ ] **Step 1: 加依赖**

Run: `flutter pub add shared_preferences`
Expected: pubspec 更新，pub get 成功。

- [ ] **Step 2: SettingsController（读写 shared_preferences）**

`lib/state/settings_controller.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_config.dart';

class SettingsController {
  SettingsController(this._prefs);
  final SharedPreferences _prefs;

  static const _kProvider = 'ai_provider';
  static const _kKey = 'ai_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kSubUrl = 'subscription_url';

  AiConfig get aiConfig => AiConfig(
        provider: AiProvider.values[_prefs.getInt(_kProvider) ?? 0],
        apiKey: _prefs.getString(_kKey) ?? '',
        baseUrl: _prefs.getString(_kBaseUrl),
      );

  Future<void> saveAi({
    required AiProvider provider,
    required String apiKey,
    String? baseUrl,
  }) async {
    await _prefs.setInt(_kProvider, provider.index);
    await _prefs.setString(_kKey, apiKey);
    if (baseUrl != null) await _prefs.setString(_kBaseUrl, baseUrl);
  }

  String? get pendingSubscriptionUrl => _prefs.getString(_kSubUrl);
  Future<void> saveSubscriptionUrl(String url) =>
      _prefs.setString(_kSubUrl, url);
}
```

- [ ] **Step 3: 集成 providers**

`lib/state/integration_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_client.dart';
import '../services/calendar_subscription_service.dart';
import 'providers.dart';
import 'settings_controller.dart';

/// 在 main() 里用实际实例覆盖（见 Task 4 Step 4）。
final sharedPrefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final settingsProvider = Provider<SettingsController>(
    (ref) => SettingsController(ref.watch(sharedPrefsProvider)));

final aiClientProvider = Provider<AiClient>(
    (ref) => AiClient(config: ref.watch(settingsProvider).aiConfig));

final subscriptionServiceProvider = Provider<CalendarSubscriptionService>(
    (ref) => CalendarSubscriptionService(ref.watch(databaseProvider)));
```

- [ ] **Step 4: main() 注入 SharedPreferences**

修改 `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'state/integration_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const PromptMeApp(),
  ));
}
```

- [ ] **Step 5: 静态检查 + Commit**

Run: `flutter analyze lib/state/`
Expected: No issues.
```bash
git add lib/state/settings_controller.dart lib/state/integration_providers.dart lib/main.dart pubspec.yaml pubspec.lock
git commit -m "feat: settings persistence + integration providers + prefs injection"
```

---

### Task 5: 设置页 + 飞书导入弹层

**Files:**
- Create: `lib/features/settings/feishu_import_sheet.dart`
- Create: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/today/today_screen.dart`（加入口按钮）

- [ ] **Step 1: 飞书导入弹层**

`lib/features/settings/feishu_import_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/import/feishu_importer.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';

class FeishuImportSheet extends ConsumerStatefulWidget {
  const FeishuImportSheet({super.key});
  @override
  ConsumerState<FeishuImportSheet> createState() => _FeishuImportSheetState();
}

class _FeishuImportSheetState extends ConsumerState<FeishuImportSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final db = ref.read(databaseProvider);
    final date = ref.read(selectedDateProvider);
    final count = await FeishuImporter(db).import(_ctrl.text, targetDate: date);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已导入 $count 条今日任务')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 18, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('粘贴飞书文档（Markdown）',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('在飞书把今天的工作文档导出/复制为 Markdown，粘到这里。',
              style: TextStyle(fontSize: 13, color: AppColors.ink60)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '# 0603\n## 重要紧急\n- [ ] ...',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.ink20)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: _import,
              child: const Text('导入今日任务'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 设置页（订阅 + AI + 飞书）**

`lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import 'package:drift/drift.dart' show Value;
import '../../services/ai/ai_config.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import 'feishu_import_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _subUrl = TextEditingController();
  final _aiKey = TextEditingController();
  final _baseUrl = TextEditingController();
  AiProvider _provider = AiProvider.claude;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(settingsProvider).aiConfig;
    _provider = cfg.provider;
    _aiKey.text = cfg.apiKey;
    _baseUrl.text = cfg.baseUrl ?? '';
  }

  @override
  void dispose() {
    _subUrl.dispose();
    _aiKey.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _addSubscription() async {
    final url = _subUrl.text.trim();
    if (url.isEmpty) return;
    final db = ref.read(databaseProvider);
    final id = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: url, displayName: '我的日历'));
    try {
      await ref.read(subscriptionServiceProvider).refresh(id, url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('订阅已添加并拉取')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('拉取失败：$e')));
      }
    }
  }

  Future<void> _saveAi() async {
    await ref.read(settingsProvider).saveAi(
          provider: _provider,
          apiKey: _aiKey.text.trim(),
          baseUrl: _baseUrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('AI 设置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppColors.paper),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('苹果日历订阅'),
          TextField(
            controller: _subUrl,
            decoration: const InputDecoration(
                hintText: 'https://p…-caldav.icloud.com.cn/published/…'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _addSubscription, child: const Text('添加并拉取')),
          const SizedBox(height: 24),
          _section('飞书任务导入'),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.paper,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (_) => const FeishuImportSheet(),
            ),
            child: const Text('粘贴 Markdown 导入'),
          ),
          const SizedBox(height: 24),
          _section('AI（自带 key）'),
          DropdownButton<AiProvider>(
            value: _provider,
            items: const [
              DropdownMenuItem(value: AiProvider.claude, child: Text('Claude')),
              DropdownMenuItem(
                  value: AiProvider.openaiCompatible,
                  child: Text('OpenAI 兼容（DeepSeek/Qwen…）')),
            ],
            onChanged: (v) => setState(() => _provider = v!),
          ),
          TextField(
            controller: _aiKey,
            decoration: const InputDecoration(hintText: 'API Key'),
            obscureText: true,
          ),
          if (_provider == AiProvider.openaiCompatible)
            TextField(
              controller: _baseUrl,
              decoration:
                  const InputDecoration(hintText: 'Base URL，如 https://api.deepseek.com'),
            ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _saveAi, child: const Text('保存 AI 设置')),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}
```

- [ ] **Step 3: 今日屏加设置入口**

在 `lib/features/today/today_screen.dart` 的 `_header` 中，把右侧 `PromptMe` 文案替换为可点击进入设置：
```dart
        IconButton(
          icon: const Icon(Icons.tune, color: AppColors.ink60),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
```
并在文件顶部 import：
```dart
import '../settings/settings_screen.dart';
```

- [ ] **Step 4: 静态检查 + 真机走查**

Run: `flutter analyze`
Expected: No issues.
Run: `flutter run -d android`
验证：设置页加订阅链接 → 今日屏「日程」段出现事件；粘贴飞书 MD → 四象限出现任务；保存 AI key。停止运行。

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/ lib/features/today/today_screen.dart
git commit -m "feat: settings screen (subscription/feishu/AI) + entry"
```

---

### Task 6: AI 接入今日屏（整理今日 / 复盘 / 实网降级）

**Files:**
- Create: `lib/features/today/widgets/ai_panel.dart`
- Modify: `lib/state/today_controller.dart`（tooHard 改走 AI，失败回退本地）
- Modify: `lib/features/today/today_screen.dart`（加两个 AI 按钮）

- [ ] **Step 1: tooHard 改为 AI 优先、本地兜底**

修改 `lib/state/today_controller.dart` 的 `tooHard`：把 `final micro = Downgrade.localFallback(...)` 一行替换为：
```dart
    final title = task?.title ?? '';
    String micro;
    try {
      final ai = ref.read(aiClientProvider);
      micro = ai.config.isConfigured
          ? await ai.downgrade(taskTitle: title, reason: reason, level: level)
          : Downgrade.localFallback(title, level);
    } catch (_) {
      micro = Downgrade.localFallback(title, level);
    }
```
并在文件顶部 import：
```dart
import 'integration_providers.dart';
```
> 说明：AI 不可用/未配置/异常 → 自动退回计划②的本地兜底，闭环不中断（spec §12 错误处理）。`today_controller_test.dart` 因 `aiConfig.isConfigured` 为空 key 时为 false，仍走本地兜底，原断言 `contains('整理农信问题')` 继续成立。

- [ ] **Step 2: AiPanel（整理今日 / 复盘结果展示）**

`lib/features/today/widgets/ai_panel.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/ai/ai_models.dart';
import '../../../theme/app_colors.dart';

class PrioritizeResultView extends StatelessWidget {
  const PrioritizeResultView({super.key, required this.result});
  final PrioritizeResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI 整理今日',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('今天先做：${result.todayFocus.join('、')}',
              style: const TextStyle(color: AppColors.q1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...result.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${s.taskTitle} → ${s.quadrant.label}（${s.reason}）'),
              )),
        ],
      ),
    );
  }
}

class ReviewResultView extends StatelessWidget {
  const ReviewResultView({super.key, required this.items});
  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI 复盘未完成',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('暂无未完成任务，或数据还不够。',
                style: TextStyle(color: AppColors.ink60)),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i.taskTitle}（${i.foggFactor}）',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${i.diagnosis} → ${i.suggestion}',
                        style: const TextStyle(color: AppColors.ink60)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 今日屏加两个 AI 按钮**

在 `lib/features/today/today_screen.dart` 的 `ListView` 顶部（StatsHeader 之后）插入一行按钮，并加处理方法：
```dart
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _prioritize(view),
                          child: const Text('整理今日(AI)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _review,
                          child: const Text('复盘未完成(AI)'),
                        ),
                      ),
                    ],
                  ),
```
在 `_TodayScreenState` 内加：
```dart
  Future<void> _prioritize(TodayView view) async {
    final titles = view.byQuadrant.values.expand((l) => l).map((t) => t.title).toList();
    if (titles.isEmpty) return;
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isConfigured) {
      _toast('先到设置里填 AI key');
      return;
    }
    try {
      final r = await ai.prioritize(
        taskTitles: titles,
        todayEvents: view.events.map((e) => e.title).toList(),
      );
      if (mounted) _showSheet(PrioritizeResultView(result: r));
    } catch (e) {
      _toast('AI 出错：$e');
    }
  }

  Future<void> _review() async {
    final db = ref.read(databaseProvider);
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isConfigured) {
      _toast('先到设置里填 AI key');
      return;
    }
    final today = ref.read(selectedDateProvider);
    final all = await db.taskDao.tasksForDate(today);
    final overdue = all
        .where((t) => t.status == TaskStatus.pending)
        .map((t) => '${t.title}（被推迟${t.rolloverCount}次，${t.quadrant.label}）')
        .toList();
    try {
      final items = await ai.review(overdue);
      if (mounted) _showSheet(ReviewResultView(items: items));
    } catch (e) {
      _toast('AI 出错：$e');
    }
  }

  void _showSheet(Widget child) => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => child,
      );

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
```
并 import：
```dart
import '../../domain/enums.dart' show TaskStatus;
import '../../state/integration_providers.dart';
import 'widgets/ai_panel.dart';
```
> 注：`TaskStatus`/`Quadrant` 已在文件早前 import；如重复 import 报错，去掉重复行即可。

- [ ] **Step 4: 静态检查 + 全量测试 + 真机走查**

Run: `flutter analyze`
Expected: No issues.
Run: `flutter test`
Expected: 全绿（AI 未配置时控制器测试仍走本地兜底）。
真机：填好 key 后点「整理今日」「复盘未完成」看 AI 结果；点「太难了」选原因，微习惯由 AI 生成（无网/无 key 自动退回本地）。

- [ ] **Step 5: Commit**

```bash
git add lib/features/today/ lib/state/today_controller.dart
git commit -m "feat: AI in app (prioritize/review + AI-first downgrade with fallback)"
```

---

### Task 7: 通知服务（定时 + 常驻 + 微习惯刷新到锁屏）

> 通知重度依赖平台与真机，按 setup + 真机走查，不做单元测试。

**Files:**
- Create: `lib/services/notification_service.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `lib/main.dart`（初始化）
- Modify: `lib/state/today_controller.dart`（tooHard 后刷新锁屏）
- Modify: `lib/state/integration_providers.dart`（notificationServiceProvider）

- [ ] **Step 1: 加依赖**

Run: `flutter pub add flutter_local_notifications timezone`
Expected: pub get 成功。

- [ ] **Step 2: Android 权限与配置**

在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 内、`<application>` 外加：
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```
并在 `<application>` 内加接收器（定时通知所需）：
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

- [ ] **Step 3: NotificationService**

`lib/services/notification_service.dart`:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _todayChannel = AndroidNotificationChannel(
    'today_focus', '今日聚焦',
    importance: Importance.high,
  );
  static const _microChannel = AndroidNotificationChannel(
    'micro_habit', '微习惯提示',
    importance: Importance.max,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final android7 = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android7?.createNotificationChannel(_todayChannel);
    await android7?.createNotificationChannel(_microChannel);
    await android7?.requestNotificationsPermission();
  }

  /// 常驻『今日·重要紧急』通知（显示在锁屏，不可滑掉）。
  Future<void> showTodayFocus(List<String> top3) async {
    await _plugin.show(
      1001,
      '今日·重要紧急',
      top3.isEmpty ? '今天还没安排' : top3.take(3).join(' · '),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'today_focus', '今日聚焦',
          ongoing: true,
          autoCancel: false,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// [太难了] 后把 2 分钟微习惯刷到锁屏。
  Future<void> showMicroHabit(String micro) async {
    await _plugin.show(
      1002,
      '现在只要 2 分钟',
      micro,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'micro_habit', '微习惯提示',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  /// 每天某时刻的定时提示。
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id, title, body, when,
      const NotificationDetails(
        android: AndroidNotificationDetails('today_focus', '今日聚焦',
            importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
```

- [ ] **Step 4: 初始化 + provider + 接入 tooHard**

`lib/main.dart` 在 `runApp` 前加：
```dart
  final notifications = NotificationService();
  await notifications.init();
```
并把它作为 override 传入（在 `integration_providers.dart` 加 provider）：
```dart
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError());
```
`main.dart` 的 overrides 增加：
```dart
      notificationServiceProvider.overrideWithValue(notifications),
```
并 import `notification_service.dart`。

在 `today_controller.dart` 的 `tooHard` 末尾（`return micro;` 之前）加：
```dart
    try {
      await ref.read(notificationServiceProvider).showMicroHabit(micro);
    } catch (_) {}
```

- [ ] **Step 5: 真机走查 + 全量测试**

Run: `flutter test`
Expected: 全绿（通知 provider 在测试里未被读取；如有测试触达，按需在测试 overrides 里提供假实现）。
Run: `flutter run -d android`
真机：授予通知权限；点「太难了」选原因 → 锁屏出现「现在只要 2 分钟：…」。停止运行。

- [ ] **Step 6: Commit**

```bash
git add lib/services/notification_service.dart lib/main.dart lib/state/integration_providers.dart lib/state/today_controller.dart android/app/src/main/AndroidManifest.xml pubspec.yaml pubspec.lock
git commit -m "feat: notifications (today-focus ongoing + micro-habit to lock screen)"
```

---

## Self-Review

**Spec 覆盖：**
- 苹果日历订阅（webcal/published，只读、可刷新）→ Task 1 + 设置页 Task 5。✅
- 飞书粘贴 Markdown 导入（解析器复用，落库到今日）→ Task 2 + 弹层 Task 5。✅
- AI 整理今日 / 复盘未完成（BYO key、可切 provider、容错解析）→ Task 3/4/6。✅
- 无底线降级实网化（AI 优先、失败回退本地）→ Task 6 Step 1。✅
- 通知：定时 + 常驻『今日·重要紧急』+ 降级刷新微习惯到锁屏 → Task 7。✅
- 设置页（订阅链接 / AI provider+key / 飞书导入入口）→ Task 5。✅
- 错误处理（订阅失败不毁旧数据、AI 失败回退、通知 try/catch）符合 spec §12。✅

**Placeholder scan：** 无 TBD/TODO；每个代码步骤含完整代码或完整命令。两处 `throw UnimplementedError()` 是 Riverpod 「必须在 main override」的标准写法，并在 Task 4/7 给出了 override 代码，非占位。✅

**Type consistency：** `CalendarSubscriptionService.{refresh,refreshAll}`、`FeishuImporter.import`、`AiConfig.{provider,apiKey,baseUrl,endpoint,effectiveModel,isConfigured}`、`AiClient.{prioritize,review,downgrade}`、`SettingsController.{aiConfig,saveAi,saveSubscriptionUrl}`、`NotificationService.{init,showTodayFocus,showMicroHabit,scheduleDaily}` 跨任务一致；复用计划① 的 `IcsParser/FeishuMarkdownParser/AiPrompts/AiResponseParser/Downgrade` 与 DAO 方法签名一致；复用计划② 的 `today_controller`/`providers`。✅

**实现期需核实（与 spec §15 一致）：**
1. 安卓 13+ 通知运行时权限弹窗；安卓 12+ 精确闹钟权限（SCHEDULE_EXACT_ALARM）实际授予情况。
2. iCloud `published` 链接 GET 是否直接回 iCalendar 文本（个别需把 `webcal://` 换 `https://`，已在 Service 处理）。
3. AI provider 是否允许安卓原生客户端直连（Claude/OpenAI/DeepSeek/Qwen/Gemini）。
4. 通知动作按钮（[做到了]/[太难了] 做进通知）= 可选升级，需 background isolate，留到第二波。

---

## 第一波三计划收口

执行顺序：计划①（地基/纯逻辑）→ 计划②（今日 UI/福格闭环）→ 计划③（集成）。每个计划自身 `flutter test` 可绿、可独立交付。三者跑完即第一波完成：苹果日历订阅 + 飞书粘贴导入 + 四象限今日时间线 + 福格闭环 + AI 整理/复盘 + 无底线降级 + 锁屏微习惯提示，可每天使用。第二波（飞书 OAuth 自动同步 + 后端）另行规划。
