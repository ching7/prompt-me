# PromptMe v1 · 阶段 1.3 收件箱屏 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 3-Tab 骨架里的「收件箱」占位屏换成真实屏:展示捕获条目(领域色标 + 来源)、手记新增(文本 + 领域标签)、按**领域标签**过滤、一键全部加入今日、单条左滑加入今日/右滑删除。（**按时间「优先今日」过滤需捕获时间戳 `capturedAt`,Task 表暂无、本计划不加,后置到加该字段时;本计划只做领域过滤。**）

**Architecture:** 沿用现有 Drift + Riverpod。新增 `InboxController` + `inboxProvider`(`StreamProvider` 监听 Plan 1.1 落好的 `TaskDao.watchInbox()`),动作走 `TaskDao` 已有方法(`insertCapture`/`addToToday`/`deleteTask`)。UI 新建轻量件:领域色 helper(`AppColors.domainColor/domainTint`)、手记表单 `CaptureSheet`、收件箱卡 `InboxCard`、收件箱屏 `InboxScreen`(替换占位 `lib/features/shell/placeholder_screens.dart` 里的 `InboxScreen`)。**不复用** `features/today/widgets/add_task_sheet.dart`(那是旧四象限今日新增,留给 Plan 1.4 待办屏改造)。**积分**这版不做(规则待 Plan 1.5,捕获 +2 动画后置)。**MAP 诊断标签**是待办屏的事(Plan 1.4 / 1.5),收件箱不显示。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;drift 2.33;flutter_test。

**工程根:** `frontend/promptme-app/`。前置:Plan 1.1 + 1.2 已落地(分支 `feat/v1-phase1.1-data-foundation`),本计划续做。**跑测试务必带 no_proxy 前缀**(见下),否则 flutter_tester 连 localhost 被代理重置、测试全崩。

**测试命令统一前缀**(本机国内代理坑,见 dev-env 记忆):
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
下文凡 `flutter test`/`flutter analyze` 都隐含已 `export` 上述前缀。

**视觉参照:** 高保真原型 `docs/superpowers/prototypes/2026-06-05-promptme-v1-mockup.html` 第 ② 屏(收件箱):领域色标卡 + `📅今日/全部` + 领域 chip 过滤 + `✓ 全部加入今日` + 左滑加入今日/右滑删除。

---

### Task 1: 领域色 helper `AppColors.domainColor / domainTint`

**Files:**
- Modify: `lib/theme/app_colors.dart`
- Test: `test/theme/app_colors_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/theme/app_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/theme/app_colors.dart';

void main() {
  test('四个默认领域映射到固定色，未分类/自定义回退 ink40', () {
    expect(AppColors.domainColor('工作'), AppColors.q1);
    expect(AppColors.domainColor('自媒体'), AppColors.q3);
    expect(AppColors.domainColor('学习'), AppColors.q2);
    expect(AppColors.domainColor('家庭'), AppColors.q4);
    expect(AppColors.domainColor(null), AppColors.ink40);
    expect(AppColors.domainColor('副业'), AppColors.ink40); // 自定义
    expect(AppColors.domainTint('工作'), AppColors.q1Tint);
    expect(AppColors.domainTint(null), AppColors.ink20);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/theme/app_colors_test.dart`
Expected: FAIL —「The method 'domainColor' isn't defined for the type 'AppColors'」

- [ ] **Step 3: 写实现**

在 `lib/theme/app_colors.dart` 的 `AppColors` 类内(`leaf` 之后)追加:

```dart
  /// 领域标签 → 色标。默认四领域固定色，未分类/自定义回退中性。
  static Color domainColor(String? label) => switch (label) {
        '工作' => q1,
        '自媒体' => q3,
        '学习' => q2,
        '家庭' => q4,
        _ => ink40,
      };

  static Color domainTint(String? label) => switch (label) {
        '工作' => q1Tint,
        '自媒体' => q3Tint,
        '学习' => q2Tint,
        '家庭' => q4Tint,
        _ => ink20,
      };
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/theme/app_colors_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/theme/app_colors.dart test/theme/app_colors_test.dart
git commit -m "feat(theme): 领域标签色标 helper domainColor/domainTint"
```

---

### Task 2: `InboxController` + `inboxProvider`

**Files:**
- Create: `lib/state/inbox_controller.dart`
- Test: `test/state/inbox_controller_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/state/inbox_controller_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/state/inbox_controller.dart';
import 'package:promptme/state/providers.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  InboxController ctl() => container.read(inboxControllerProvider);

  test('capture 进收件箱（带领域），inboxProvider 流出', () async {
    await ctl().capture(text: '研究 MCP 协议', domain: '学习');
    await ctl().capture(text: '没标签的');
    final inbox = await container.read(inboxProvider.future);
    expect(inbox.map((t) => t.title), ['没标签的', '研究 MCP 协议']); // 新→旧
    expect(inbox.last.domain, '学习');
  });

  test('addToToday 把条目移出收件箱、置今天', () async {
    await ctl().capture(text: 'A');
    final id = (await container.read(inboxProvider.future)).single.id;
    await ctl().addToToday(id);
    final t = await db.taskDao.getById(id);
    final n = DateTime.now();
    expect(t!.scheduledDate, DateTime(n.year, n.month, n.day));
    expect(await container.read(inboxProvider.future), isEmpty);
  });

  test('addAllToToday 批量清空收件箱', () async {
    await ctl().capture(text: 'A');
    await ctl().capture(text: 'B');
    final ids =
        (await container.read(inboxProvider.future)).map((t) => t.id).toList();
    await ctl().addAllToToday(ids);
    expect(await container.read(inboxProvider.future), isEmpty);
  });

  test('delete 移除条目', () async {
    await ctl().capture(text: 'A');
    final id = (await container.read(inboxProvider.future)).single.id;
    await ctl().delete(id);
    expect(await container.read(inboxProvider.future), isEmpty);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/state/inbox_controller_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../inbox_controller.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/state/inbox_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import 'providers.dart';

class InboxController {
  InboxController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  /// 手记/桌面捕获：source=capture、scheduledDate=null 进收件箱。
  Future<void> capture({required String text, String? domain}) =>
      _db.taskDao.insertCapture(title: text, domain: domain);

  /// 单条加入今日。
  Future<void> addToToday(int id) {
    final n = DateTime.now();
    return _db.taskDao.addToToday(id, DateTime(n.year, n.month, n.day));
  }

  /// 一键把多条加入今日。
  Future<void> addAllToToday(List<int> ids) async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    for (final id in ids) {
      await _db.taskDao.addToToday(id, today);
    }
  }

  /// 删除条目（连带行为事件，与 TodayController.deleteTask 一致）。
  Future<void> delete(int id) async {
    await _db.taskEventDao.deleteForTask(id);
    await _db.taskDao.deleteTask(id);
  }
}

final inboxControllerProvider =
    Provider<InboxController>((ref) => InboxController(ref));

/// 收件箱列表：无排期的待办，新→旧（见 TaskDao.watchInbox）。
final inboxProvider = StreamProvider.autoDispose<List<Task>>(
    (ref) => ref.watch(databaseProvider).taskDao.watchInbox());
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/state/inbox_controller_test.dart`
Expected: PASS（4 条全过）

- [ ] **Step 5: 提交**

```bash
git add lib/state/inbox_controller.dart test/state/inbox_controller_test.dart
git commit -m "feat(state): InboxController + inboxProvider"
```

---

### Task 3: 手记表单 `CaptureSheet`(文本 + 领域标签)

> 底部弹出表单:多行文本 + 四个领域 chip(可不选=未分类)+「记一笔」按钮 → `InboxController.capture` → 关闭。回调式,不直接依赖 provider,便于 widget 测试。

**Files:**
- Create: `lib/features/inbox/capture_sheet.dart`
- Test: `test/features/inbox/capture_sheet_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/inbox/capture_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/inbox/capture_sheet.dart';

void main() {
  testWidgets('输入文本 + 选领域 → onCapture 回调带值', (tester) async {
    String? gotText;
    String? gotDomain;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CaptureSheet(onCapture: (t, d) {
          gotText = t;
          gotDomain = d;
        }),
      ),
    ));

    await tester.enterText(find.byType(TextField), '研究 MCP 协议');
    await tester.tap(find.text('学习'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '记一笔'));
    await tester.pump();

    expect(gotText, '研究 MCP 协议');
    expect(gotDomain, '学习');
  });

  testWidgets('空文本时「记一笔」不回调', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CaptureSheet(onCapture: (_, __) => called = true)),
    ));
    await tester.tap(find.widgetWithText(FilledButton, '记一笔'));
    await tester.pump();
    expect(called, false);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inbox/capture_sheet_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../capture_sheet.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/inbox/capture_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../domain/domains.dart';
import '../../theme/app_colors.dart';

/// 手记表单：文本 + 可选领域标签 → onCapture(text, domain)。domain 为 null = 未分类。
class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key, required this.onCapture});
  final void Function(String text, String? domain) onCapture;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _ctrl = TextEditingController();
  String? _domain;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onCapture(text, _domain);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('记一笔',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '想到什么先记下来…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final d in kDefaultDomains)
                ChoiceChip(
                  label: Text(d),
                  selected: _domain == d,
                  avatar: CircleAvatar(
                      radius: 5, backgroundColor: AppColors.domainColor(d)),
                  onSelected: (sel) =>
                      setState(() => _domain = sel ? d : null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('记一笔')),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inbox/capture_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/inbox/capture_sheet.dart test/features/inbox/capture_sheet_test.dart
git commit -m "feat(inbox): 手记表单 CaptureSheet(文本+领域标签)"
```

---

### Task 4: 收件箱卡 `InboxCard`

> 一条捕获:左侧领域色标竖条 + 标题 + 一行 meta(领域 chip 或「未分类」· 来源 · 时间)。纯展示件,数据由 `Task` 传入,便于 widget 测试。

**Files:**
- Create: `lib/features/inbox/inbox_card.dart`
- Test: `test/features/inbox/inbox_card_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/inbox/inbox_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/inbox/inbox_card.dart';

void main() {
  testWidgets('有领域显标签，无领域显未分类，含标题', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          InboxCard(title: '研究 MCP 协议', domain: '学习', subtitle: '💻 桌面 · 刚刚'),
          InboxCard(title: '没标签', domain: null, subtitle: '✍️ 手记 · 昨天'),
        ]),
      ),
    ));
    expect(find.text('研究 MCP 协议'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('没标签'), findsOneWidget);
    expect(find.text('未分类'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inbox/inbox_card_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../inbox_card.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/inbox/inbox_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 收件箱单条卡：领域色标 + 标题 + meta（领域/未分类 · 来源 · 时间）。
class InboxCard extends StatelessWidget {
  const InboxCard({
    super.key,
    required this.title,
    required this.domain,
    required this.subtitle,
  });

  final String title;
  final String? domain;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink20),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.domainColor(domain)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (hasDomain) ...[
                        CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.domainColor(domain)),
                        const SizedBox(width: 4),
                        Text(domain!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.domainColor(domain))),
                      ] else
                        Text('未分类',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink40)),
                      const SizedBox(width: 9),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.ink40)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/inbox/inbox_card_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/inbox/inbox_card.dart test/features/inbox/inbox_card_test.dart
git commit -m "feat(inbox): 收件箱卡 InboxCard(领域色标+meta)"
```

---

### Task 5: 收件箱屏 `InboxScreen`(列表 + 过滤 + 批量 + 滑动 + FAB)

> 替换占位 `InboxScreen`。`ConsumerWidget` 读 `inboxProvider`;顶部过滤条(`📅今日`/`全部` + 领域 chip,默认今日优先)+ `✓ 全部加入今日` 按钮;列表用 `Dismissible` 包 `InboxCard`(右滑→加入今日 endToStart、左滑→删除 startToEnd);右下 FAB → 弹 `CaptureSheet`。「今日」过滤 = 按 `id`(代表捕获时间)取今天捕获;MVP 先以「全部/今日」切换 + 领域筛选 + 今日置顶呈现。

**Files:**
- Create: `lib/features/inbox/inbox_screen.dart`
- Modify: `lib/features/shell/placeholder_screens.dart`、`lib/features/shell/home_shell.dart`
- Test: `test/features/inbox/inbox_screen_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/inbox/inbox_screen_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/inbox/inbox_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('渲染收件箱条目 + 全部加入今日按钮 + FAB', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.taskDao.insertCapture(title: '研究 MCP 协议', domain: '学习');
    await db.taskDao.insertCapture(title: '给奶奶约复查');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: InboxScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('研究 MCP 协议'), findsOneWidget);
    expect(find.text('给奶奶约复查'), findsOneWidget);
    expect(find.textContaining('全部加入今日'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('点全部加入今日 → 列表清空', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.taskDao.insertCapture(title: 'A');
    await db.taskDao.insertCapture(title: 'B');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: InboxScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('全部加入今日'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/inbox/inbox_screen_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../inbox_screen.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/inbox/inbox_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/domains.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../state/inbox_controller.dart';
import 'capture_sheet.dart';
import 'inbox_card.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  // 仅领域过滤可真做；按时间「优先今日」需捕获时间戳（Task 表暂无 capturedAt），后置。
  String? _domainFilter;

  List<Task> _filter(List<Task> items) {
    if (_domainFilter == null) return items;
    return items.where((t) => t.domain == _domainFilter).toList();
  }

  void _openCapture() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        onCapture: (text, domain) {
          ref.read(inboxControllerProvider).capture(text: text, domain: domain);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openCapture,
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
        data: (all) {
          final items = _filter(all);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              Row(children: [
                const Text('收件箱',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('${all.length} 条待整理',
                    style: TextStyle(color: AppColors.ink40, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              _filterBar(),
              const SizedBox(height: 8),
              if (items.isNotEmpty)
                _bulkAddButton(items.map((t) => t.id).toList()),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('收件箱空了 · 想到什么按 + 记一笔',
                        style: TextStyle(color: AppColors.ink40)),
                  ),
                )
              else
                for (final t in items) _dismissibleCard(t),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('领域',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink40)),
        for (final d in kDefaultDomains)
          FilterChip(
            label: Text(d),
            selected: _domainFilter == d,
            avatar: CircleAvatar(
                radius: 5, backgroundColor: AppColors.domainColor(d)),
            onSelected: (sel) =>
                setState(() => _domainFilter = sel ? d : null),
          ),
      ],
    );
  }

  Widget _bulkAddButton(List<int> ids) {
    return InkWell(
      onTap: () => ref.read(inboxControllerProvider).addAllToToday(ids),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.leaf.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.leaf.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('✓ 全部加入今日',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.leaf,
                    fontSize: 13)),
            Text('当前 ${ids.length} 条 →',
                style: TextStyle(color: AppColors.ink40, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dismissibleCard(Task t) {
    return Dismissible(
      key: ValueKey(t.id),
      background: Container(
        alignment: Alignment.centerLeft,
        color: AppColors.q1, // 左滑→删除
        padding: const EdgeInsets.only(left: 20),
        child: const Text('删除', style: TextStyle(color: Colors.white)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        color: AppColors.leaf, // 右滑→加入今日
        padding: const EdgeInsets.only(right: 20),
        child: const Text('加入今日', style: TextStyle(color: Colors.white)),
      ),
      confirmDismiss: (dir) async {
        final ctl = ref.read(inboxControllerProvider);
        if (dir == DismissDirection.endToStart) {
          await ctl.addToToday(t.id);
        } else {
          await ctl.delete(t.id);
        }
        return true;
      },
      child: InboxCard(
        title: t.title,
        domain: t.domain,
        subtitle: t.source == TaskSource.capture ? '💻 捕获' : '✍️ 手记',
      ),
    );
  }
}
```

- [ ] **Step 4: 接入骨架(替换占位 InboxScreen)**

`lib/features/shell/placeholder_screens.dart`:删除其中的 `InboxScreen` 类(占位版)。
`lib/features/shell/home_shell.dart`:把 `import 'placeholder_screens.dart';` 之外**新增** `import '../inbox/inbox_screen.dart';`;`_screens` 列表里的 `InboxScreen()` 现在指向真实屏(去掉 const 若 InboxScreen 构造非 const —— 它是 `ConsumerStatefulWidget` 带 const 构造,可保留 `const InboxScreen()`)。`TodoScreen`/`ReviewScreen` 仍用占位。

- [ ] **Step 5: 修 `home_shell_test`(关键:InboxScreen 现在是 ConsumerWidget)**

`HomeShell` 的 `IndexedStack` 会**构建全部三屏**,其中真实 `InboxScreen` 读 `inboxProvider` → 需要 `ProviderScope` + `databaseProvider`,否则 pump 即崩。把 `test/features/shell/home_shell_test.dart` 改成:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/shell/home_shell.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('三 Tab 默认在待办、收件箱有 FAB、可切到复盘', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();

    // 底部三个 Tab 标签都在
    expect(find.text('收件箱'), findsWidgets); // 导航标签（收件箱屏也有同名标题，故 findsWidgets）
    expect(find.text('待办'), findsWidgets);
    expect(find.text('复盘'), findsOneWidget);

    // 默认选中「待办」→ 待办占位屏标题可见
    expect(find.text('待办 · 占位'), findsOneWidget);

    // 切到收件箱 → 真实屏的 FAB 出现（占位屏没有 FAB）
    await tester.tap(find.text('收件箱').last);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 切到复盘
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('复盘 · 占位'), findsOneWidget);
  });
}
```

> 说明:`find.text('收件箱')` 现在会同时命中底部导航标签 + 收件箱屏标题(IndexedStack 里 InboxScreen 一直在树上,但未选中时 offstage、`find.text` 默认跳过 offstage,所以默认在待办时只命中导航标签 1 个;为稳妥用 `findsWidgets` + `.last` 点导航项)。

Run: `flutter test test/features/inbox/ test/features/shell/home_shell_test.dart`
Expected: PASS

- [ ] **Step 6: 全量回归 + analyze + 提交**

Run: `flutter analyze` → 无 issue;`flutter test` → 全绿。

```bash
git add -A
git commit -m "feat(inbox): 真实收件箱屏(过滤/批量加入今日/滑动/手记 FAB)+ 接入骨架"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- 「收件箱」Tab 是真实屏:列出捕获(领域色标 + 来源 + 待整理计数)、FAB 弹手记表单(文本 + 领域)、领域过滤条、`✓ 全部加入今日`、单条左滑删除 / 右滑加入今日。(时间「优先今日」过滤后置,需 `capturedAt`。)
- 新增 `InboxController`/`inboxProvider`/`CaptureSheet`/`InboxCard`/`InboxScreen` + `AppColors.domainColor/domainTint`;占位 `InboxScreen` 已移除。
- 未触碰待办/复盘占位屏;未引入积分/MAP(后置)。

## 衔接下一计划

Plan 1.4(待办屏 GTD):把「待办」占位换成真实屏——GTD 智能清单(今日待办置顶 / 下一步 / 即将 / 将来也许)+ 领域色标 + 面包屑 + 底部 meta 行(🍅 占位 / MAP 标签位)+ 逾期态 + 右上角 chip(连续天数/今日完成/总积分)+ FAB + 我做到了/太难了 swipe(复用 `TodayController`)。届时改造 `add_task_sheet`、复用 `stats_header`/`task_card`(或新建待办卡)。
