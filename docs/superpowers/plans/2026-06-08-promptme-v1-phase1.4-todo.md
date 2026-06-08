# PromptMe v1 · 阶段 1.4 待办屏(今日执行版)实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 3-Tab 骨架里的「待办」占位屏换成真实**今日执行屏**:顶部日期 + stats chip(连续天数 / 今日完成),`今日待办` 列表(任务卡:领域色标 + 标题 + 领域面包屑 + 完成勾选 + 逾期态)、`已完成` 列表,右下 FAB 加任务到今日。

**Architecture:** 复用现有数据/控制器:`TaskDao.watchTasksForDate(today)`(今日全部任务,含 pending/done)、`TodayController.complete/reopen/deleteTask`、`streakProvider`。新增:`todoTodayProvider`(把今日任务分成 待办/已完成)、`TodoController.addToday`(文本+领域 → 排今天)、`StatsChip`、`TodoCard`、`TodoScreen`(替换占位)。FAB **复用 Plan 1.3 的 `CaptureSheet`**(同一表单,回调改成「加入今日」)。

**范围边界(本计划不做,后置):** 完整 GTD 桶(下一步行动 / 即将到来 / 将来也许)——需加「GTD 桶」字段 + 排程/整理流程;**积分总数**——需积分存储(Plan 1.5 正反馈);**MAP 诊断标签 / 🍅 番茄 / 我做到了-太难了 滑动 + 庆祝 + 微习惯**——Plan 1.5 福格闭环 + 番茄;**项目面包屑的「›项目」段**——模型暂无项目文本,只显领域。本计划完成动作用**点击勾选**(非滑动)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;drift 2.33;flutter_test。

**工程根:** `frontend/promptme-app/`。前置:Plan 1.1–1.3 已在 master。本计划在新分支 `feat/v1-phase1.4-todo` 上做(由控制器在执行前用 git worktrees / 建分支保证)。

**⚠️ 跑测试/analyze 必带前缀**(国内代理坑,否则 flutter_tester 连 localhost 被重置全崩):
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
下文 `flutter test`/`flutter analyze` 都隐含已 export 此前缀。**别 `flutter clean`**(会清掉已缓存的 sqlite3 `.so`,又要联网下)。

**视觉参照:** 原型 `docs/superpowers/prototypes/2026-06-05-promptme-v1-mockup.html` 第 ③ 屏(待办):顶部日期 + 紧凑 stats chip;★今日待办 区;任务卡 = 领域色标竖条 + 标题 + 面包屑 + 底部 meta 行。本计划 meta 行先只放领域 + 逾期(MAP/🍅 后置)。

---

### Task 1: `TodoController.addToday` + `todoTodayProvider` + `TodoToday` 模型

**Files:**
- Create: `lib/state/todo_controller.dart`
- Test: `test/state/todo_controller_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/state/todo_controller_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/todo_controller.dart';

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

  TodoController ctl() => container.read(todoControllerProvider);

  test('addToday 排今天 + 进 todoTodayProvider 的待办区', () async {
    await ctl().addToday(text: '写 Java 代码', domain: '工作');
    final view = await container.read(todoTodayProvider.future);
    expect(view.pending.single.title, '写 Java 代码');
    expect(view.pending.single.domain, '工作');
    expect(view.doneCount, 0);
    expect(view.totalCount, 1);
  });

  test('complete 把任务移到已完成区', () async {
    await ctl().addToday(text: 'A');
    final id = (await container.read(todoTodayProvider.future)).pending.single.id;
    await ctl().complete(id);
    final view = await container.read(todoTodayProvider.future);
    expect(view.pending, isEmpty);
    expect(view.done.single.id, id);
    expect(view.doneCount, 1);
    expect(view.totalCount, 1);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/state/todo_controller_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../todo_controller.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/state/todo_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import 'providers.dart';
import 'today_controller.dart';

/// 今日视图：待办(pending)+ 已完成(done)。
class TodoToday {
  TodoToday(this.pending, this.done);
  final List<Task> pending;
  final List<Task> done;
  int get doneCount => done.length;
  int get totalCount => pending.length + done.length;
}

class TodoController {
  TodoController(this.ref);
  final Ref ref;
  AppDatabase get _db => ref.read(databaseProvider);

  /// 直接加一条到今日(文本 + 可选领域)。
  Future<void> addToday({required String text, String? domain}) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return _db.taskDao.insertCapture(
        title: text, domain: domain, scheduledDate: today);
  }

  /// 完成 / 重开 / 删除：复用 TodayController（含事件记录）。
  Future<void> complete(int id) =>
      ref.read(todayControllerProvider).complete(id);
  Future<void> reopen(int id) =>
      ref.read(todayControllerProvider).reopen(id);
  Future<void> delete(int id) =>
      ref.read(todayControllerProvider).deleteTask(id);
}

final todoControllerProvider =
    Provider<TodoController>((ref) => TodoController(ref));

/// 今日任务流 → 分待办 / 已完成。
final todoTodayProvider = StreamProvider<TodoToday>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.taskDao.watchTasksForDate(date).map((rows) {
    final pending = rows.where((t) => t.status == TaskStatus.pending).toList();
    final done = rows.where((t) => t.status == TaskStatus.done).toList();
    return TodoToday(pending, done);
  });
});
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/state/todo_controller_test.dart`
Expected: PASS（2 条）

- [ ] **Step 5: 提交**

```bash
git add lib/state/todo_controller.dart test/state/todo_controller_test.dart
git commit -m "feat(state): TodoController.addToday + todoTodayProvider"
```

---

### Task 2: `StatsChip`(连续天数 / 今日完成)

> 右上角紧凑 chip:🔥连续天数 │ ◎今日完成/总数。积分后置(Plan 1.5),本版不放。回调式入参,便于测试。

**Files:**
- Create: `lib/features/todo/stats_chip.dart`
- Test: `test/features/todo/stats_chip_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/todo/stats_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/todo/stats_chip.dart';

void main() {
  testWidgets('显示连续天数与今日完成', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsChip(streak: 7, done: 2, total: 5)),
    ));
    expect(find.textContaining('7'), findsWidgets); // 🔥7
    expect(find.textContaining('2/5'), findsOneWidget); // ◎2/5
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/stats_chip_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../stats_chip.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/todo/stats_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatsChip extends StatelessWidget {
  const StatsChip(
      {super.key, required this.streak, required this.done, required this.total});
  final int streak;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('🔥$streak',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        _sep(),
        Text('◎$done/$total',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.q3)),
      ]),
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 12,
        color: AppColors.ink20,
        margin: const EdgeInsets.symmetric(horizontal: 9),
      );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/todo/stats_chip_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/todo/stats_chip.dart test/features/todo/stats_chip_test.dart
git commit -m "feat(todo): StatsChip(连续天数/今日完成)"
```

---

### Task 3: `TodoCard`(领域色标 + 标题 + 面包屑 + 完成勾选 + 逾期态)

> 任务卡:左侧领域色条 + 圆形勾选(点→完成)+ 标题(完成态划线)+ 面包屑(领域 chip)+ 逾期 flag(`overdue=true` 时显「已推迟 N 次」)。回调式 `onToggle`,纯展示 + 一个动作,便于测试。

**Files:**
- Create: `lib/features/todo/todo_card.dart`
- Test: `test/features/todo/todo_card_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/todo/todo_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/todo/todo_card.dart';

void main() {
  testWidgets('显示标题 + 领域 + 点击勾选回调', (tester) async {
    var toggled = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '写 Java 代码',
          domain: '工作',
          done: false,
          overdue: false,
          rolloverCount: 0,
          onToggle: () => toggled = true,
        ),
      ),
    ));
    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('todo-toggle')));
    expect(toggled, true);
  });

  testWidgets('逾期态显示已推迟次数', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '整理 API 文档',
          domain: null,
          done: false,
          overdue: true,
          rolloverCount: 2,
          onToggle: () {},
        ),
      ),
    ));
    expect(find.textContaining('已推迟 2 次'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/todo_card_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../todo_card.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/todo/todo_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.title,
    required this.domain,
    required this.done,
    required this.overdue,
    required this.rolloverCount,
    required this.onToggle,
  });

  final String title;
  final String? domain;
  final bool done;
  final bool overdue;
  final int rolloverCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: overdue ? AppColors.q1.withValues(alpha: .38) : AppColors.ink20),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.domainColor(domain)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 13, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      key: const ValueKey('todo-toggle'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                          done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: done ? AppColors.leaf : AppColors.ink40,
                          size: 22),
                      onPressed: onToggle,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: done ? AppColors.ink40 : AppColors.ink,
                              )),
                          const SizedBox(height: 6),
                          Row(children: [
                            if (hasDomain) ...[
                              CircleAvatar(
                                  radius: 3,
                                  backgroundColor:
                                      AppColors.domainColor(domain)),
                              const SizedBox(width: 4),
                              Text(domain!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.domainColor(domain))),
                            ] else
                              Text('未分类',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.ink40)),
                            if (overdue) ...[
                              const SizedBox(width: 9),
                              Text('⏰ 已推迟 $rolloverCount 次',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.q1)),
                            ],
                          ]),
                        ],
                      ),
                    ),
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

Run: `flutter test test/features/todo/todo_card_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/todo/todo_card.dart test/features/todo/todo_card_test.dart
git commit -m "feat(todo): TodoCard(领域色标+面包屑+完成勾选+逾期)"
```

---

### Task 4: `TodoScreen` + 接入骨架

> 替换占位 `TodoScreen`。`ConsumerWidget` 读 `todoTodayProvider` + `streakProvider`;顶部「日期 + StatsChip」;`★ 今日待办`(pending,逾期=`scheduledDate<今天||rolloverCount>0` 这里今日任务恒为今天,逾期先用 `rolloverCount>0` 判定)；`已完成` 区(done,点勾选可重开);右下 FAB → `CaptureSheet`(回调=`addToday`)。空态提示。`SafeArea` 包 body(避状态栏,沿用收件箱修复)。

**Files:**
- Create: `lib/features/todo/todo_screen.dart`
- Modify: `lib/features/shell/placeholder_screens.dart`(删占位 TodoScreen)、`lib/features/shell/home_shell.dart`(import 真实 TodoScreen)
- Test: `test/features/todo/todo_screen_test.dart`、`test/features/shell/home_shell_test.dart`(默认 Tab 改断言)

- [ ] **Step 1: 写失败测试**

新建 `test/features/todo/todo_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/todo/todo_screen.dart';
import 'package:promptme/state/providers.dart';
import 'package:promptme/state/todo_controller.dart';

void main() {
  testWidgets('渲染今日待办 + 已完成 + StatsChip + FAB', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.textContaining('今日待办'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('点勾选 → 移到已完成', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(todoControllerProvider).addToday(text: 'A');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: TodoScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('todo-toggle')).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('已完成'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/todo_screen_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../todo_screen.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/todo/todo_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../state/providers.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';
import '../inbox/capture_sheet.dart';
import 'stats_chip.dart';
import 'todo_card.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  /// 手算「M月d日 · 周X」，避免依赖 intl locale 数据（widget 测试无需初始化）。
  String _dateLabel() {
    final n = DateTime.now();
    const wk = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${n.month}月${n.day}日 · ${wk[n.weekday % 7]}';
  }

  void _openAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        onCapture: (text, domain) {
          ref.read(todoControllerProvider).addToday(text: text, domain: domain);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todoTodayProvider);
    final streak = ref.watch(streakProvider).value ?? 0;
    final ctl = ref.read(todoControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('出错了：$e')),
          data: (view) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dateLabel(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink60)),
                    StatsChip(
                        streak: streak,
                        done: view.doneCount,
                        total: view.totalCount),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionHeader('★ 今日待办', '${view.pending.length} 件'),
                if (view.pending.isEmpty)
                  _empty('今天还没排任务 · 按 + 加一件')
                else
                  for (final t in view.pending) _card(ctl, t, false),
                if (view.done.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionHeader('已完成', '${view.done.length}'),
                  for (final t in view.done) _card(ctl, t, true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(TodoController ctl, Task t, bool done) => TodoCard(
        title:
            (t.currentPromptText?.isNotEmpty ?? false) ? t.currentPromptText! : t.title,
        domain: t.domain,
        done: done,
        overdue: !done && t.rolloverCount > 0,
        rolloverCount: t.rolloverCount,
        onToggle: () => done ? ctl.reopen(t.id) : ctl.complete(t.id),
      );

  Widget _sectionHeader(String title, String count) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.ink)),
          const SizedBox(width: 9),
          Expanded(child: Container(height: 1, color: AppColors.ink20)),
          const SizedBox(width: 9),
          Text(count,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink40)),
        ]),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(text, style: TextStyle(color: AppColors.ink40))),
      );
}
```

- [ ] **Step 4: 接入骨架**

`lib/features/shell/placeholder_screens.dart`:删除占位 `TodoScreen` 类。
`lib/features/shell/home_shell.dart`:新增 `import '../todo/todo_screen.dart';`;`_screens` 里 `TodoScreen()` 现指向真实屏(保留 `const`,TodoScreen 是 const 构造)。`InboxScreen`(Plan 1.3)与 `ReviewScreen`(占位)不变。

- [ ] **Step 5: 修 `home_shell_test`(默认 Tab=待办 现在是真实屏,需 DB)**

`HomeShell` 的 IndexedStack 现在含真实 `TodoScreen`(读 `todoTodayProvider`/`streakProvider`),默认就选中它 → pump 必须有 `ProviderScope + databaseProvider`(Plan 1.3 已加内存 DB)。把 `test/features/shell/home_shell_test.dart` 的「默认待办占位」断言从 `find.text('待办 · 占位')` 改成断言真实待办屏元素,例如:

```dart
// 默认选中「待办」→ 真实待办屏:今日待办区可见
expect(find.textContaining('今日待办'), findsOneWidget);
```

并把切到「收件箱」「复盘」的断言保持(收件箱真实屏=FAB 可见;复盘仍占位='复盘 · 占位')。其余结构沿用 Plan 1.3 的 home_shell_test（已有 ProviderScope + 内存 DB）。

- [ ] **Step 6: 跑测试确认通过**

Run: `flutter test test/features/todo/todo_screen_test.dart test/features/shell/home_shell_test.dart`
Expected: PASS

- [ ] **Step 7: 全量回归 + analyze + 提交**

Run: `flutter analyze` → 无 issue;`flutter test` → 全绿。

```bash
git add -A
git commit -m "feat(todo): 真实待办屏(今日待办/已完成/StatsChip/FAB)+ 接入骨架"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- 「待办」Tab 是真实屏:顶部日期 + StatsChip(🔥连续天数 / ◎今日完成),`★ 今日待办` 列表(任务卡 = 领域色标 + 标题 + 领域面包屑 + 圆形勾选 + 逾期态),`已完成` 区(点勾选可重开),FAB 弹 CaptureSheet 加任务到今日。
- 新增 `TodoController`/`todoTodayProvider`/`TodoToday`/`StatsChip`/`TodoCard`/`TodoScreen`;占位 TodoScreen 已删。
- 未触碰复盘占位;未引入积分/MAP/🍅/滑动/庆祝(Plan 1.5);完整 GTD 桶后置。

## 衔接下一计划

Plan 1.5(福格闭环 + 番茄 + 正反馈):任务卡加 我做到了(左滑→complete + 庆祝)/ 太难了(右滑→压缩版 P/A/M sheet → 降级 → 微习惯/锁屏);番茄钟(专注屏 + 🍅 + 完成庆祝);积分系统(捕获+2/完成/番茄,StatsChip 加 ★总积分);MAP 诊断标签(AI 异步)。
