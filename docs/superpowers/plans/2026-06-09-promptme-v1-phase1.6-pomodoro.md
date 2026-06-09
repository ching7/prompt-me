# PromptMe v1 · 阶段 1.6 番茄钟(手机核心)实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给任务加番茄钟:每任务带 🍅(预估/已完成);待办卡上点 🍅 进**专注屏**(标准 25 分倒计时环 + 任务名 + 暂停/放弃)；倒计时到点 → +1 🍅 + 完成态(🍅 完成 · 短休 5 分);放弃 → 直接退出不计数。

**Architecture:** `Tasks` 加 `tomatoEst`(预估,可空)+ `tomatoDone`(已完成,默认 0)两列(schema v3 迁移)。`TaskDao` 加 `incrementTomato`/`setTomatoEst`;`TodoController` 加 `completeTomato` 代理。新建 `FocusScreen`(`ConsumerStatefulWidget`,`Timer.periodic` 倒计时,`workSeconds` 可注入便于测试),到点调 `completeTomato` 并转完成态。`TodoCard` 加 `🍅 done/est` 展示 + `onFocus` 回调;`TodoScreen` 点 🍅 → `Navigator.push` FocusScreen。

**范围边界(不做):** AI 估 🍅 数(`tomatoEst` 暂只能为空或手动,AI 在后续计划)、喂 A 诊断 / 放弃→标「需提示」(AI 计划)、积分(Plan 1.7)、5/15 自动休息循环(本版完成态只给「短休 5 分」文字提示,不自动进休息计时)、桌面番茄(阶段 ②)、`复盘` 的番茄会话聚合表(复盘计划再加)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;drift 2.33;flutter_test。

**工程根:** `frontend/promptme-app/`。前置:Plan 1.1–1.5 已在 master。本计划在新分支 `feat/v1-phase1.6-pomodoro` 上做。

**⚠️ 跑测试/analyze 必带前缀**(国内代理坑):
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
下文命令隐含已 export。**别 `flutter clean`**(清掉已缓存 sqlite3 `.so`)。drift 改表后跑 `dart run build_runner build --delete-conflicting-outputs`。

**视觉参照:** 原型第 ⑤ 屏(专注屏:倒计时环 + 任务名 + 暂停/放弃 + 完成态)。

---

### Task 1: `Tasks.tomatoEst/tomatoDone` 列 + schema v3 + DAO + TodoController.completeTomato

**Files:**
- Modify: `lib/data/database.dart`、`lib/data/daos/task_dao.dart`、`lib/state/todo_controller.dart`
- Regenerate: `lib/data/database.g.dart`
- Test: `test/data/task_dao_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/data/task_dao_test.dart` 的 `main()` 内追加:

```dart
test('番茄列：incrementTomato 累加、setTomatoEst 设预估', () async {
  final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');
  var t = await db.taskDao.getById(id);
  expect(t!.tomatoDone, 0);
  expect(t.tomatoEst, isNull);

  await db.taskDao.setTomatoEst(id, 3);
  await db.taskDao.incrementTomato(id);
  await db.taskDao.incrementTomato(id);
  t = await db.taskDao.getById(id);
  expect(t!.tomatoEst, 3);
  expect(t.tomatoDone, 2);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/task_dao_test.dart`
Expected: FAIL —「The named parameter / getter 'tomatoEst' isn't defined」

- [ ] **Step 3: 加列 + 迁移**

`lib/data/database.dart` 的 `Tasks` 表里,`domain` 那行后追加:
```dart
  TextColumn get domain => text().nullable()();
  IntColumn get tomatoEst => integer().nullable()();
  IntColumn get tomatoDone => integer().withDefault(const Constant(0))();
```
`schemaVersion` 从 `2` 改 `3`;`migration` 的 `onUpgrade` 内追加:
```dart
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.domain);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.tomatoEst);
            await m.addColumn(tasks, tasks.tomatoDone);
          }
        },
```

- [ ] **Step 4: 重新生成 drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成成功,`database.g.dart` 的 `Task`/`TasksCompanion` 多出 `tomatoEst`/`tomatoDone`。

- [ ] **Step 5: 写 DAO + 控制器实现**

`lib/data/daos/task_dao.dart` 的 `TaskDao` 类内追加:
```dart
  /// 完成一个番茄：tomatoDone += 1。
  Future<void> incrementTomato(int id) async {
    final t = await getById(id);
    await (update(tasks)..where((x) => x.id.equals(id)))
        .write(TasksCompanion(tomatoDone: Value((t?.tomatoDone ?? 0) + 1)));
  }

  /// 设番茄预估数。
  Future<void> setTomatoEst(int id, int est) =>
      (update(tasks)..where((x) => x.id.equals(id)))
          .write(TasksCompanion(tomatoEst: Value(est)));
```

`lib/state/todo_controller.dart` 的 `TodoController` 类内追加(complete 等之后):
```dart
  /// 完成一个番茄（+1 🍅）。
  Future<void> completeTomato(int id) => _db.taskDao.incrementTomato(id);
```

- [ ] **Step 6: 跑测试确认通过**

Run: `flutter test test/data/task_dao_test.dart`
Expected: PASS

- [ ] **Step 7: 提交**

```bash
git add lib/data/database.dart lib/data/database.g.dart lib/data/daos/task_dao.dart lib/state/todo_controller.dart test/data/task_dao_test.dart
git commit -m "feat(data): Tasks.tomatoEst/tomatoDone(v3)+ incrementTomato/setTomatoEst + completeTomato"
```

---

### Task 2: `FocusScreen`(倒计时环 + 暂停/放弃 + 完成→+🍅)

> 全屏专注:倒计时环(`CircularProgressIndicator` + 中间 MM:SS)+ 任务名 + 暂停/放弃。`Timer.periodic` 每秒减;到点 → `completeTomato` → 转完成态(🍅 完成 +1 · 短休 5 分 + 返回)。`workSeconds` 入参默认 1500(25 分),测试传小值。放弃 = 直接 `Navigator.pop`,不计数。

**Files:**
- Create: `lib/features/todo/focus_screen.dart`
- Test: `test/features/todo/focus_screen_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/todo/focus_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/todo/focus_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('显示任务名 + 倒计时；到点 +1🍅 转完成态', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: FocusScreen(taskId: id, taskTitle: '写 Java 代码', workSeconds: 2),
      ),
    ));
    await tester.pump();
    expect(find.text('写 Java 代码'), findsOneWidget);
    expect(find.text('00:02'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // → 0 → 完成
    await tester.pump(); // completeTomato 异步 + setState
    await tester.pumpAndSettle();

    expect(find.textContaining('完成'), findsOneWidget); // 完成态
    final t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 1);
  });

  testWidgets('放弃 → 退出且不计数', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: 'A');

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => FocusScreen(
                      taskId: id, taskTitle: 'A', workSeconds: 60))),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();

    expect(find.text('go'), findsOneWidget); // 已退回
    final t = await db.taskDao.getById(id);
    expect(t!.tomatoDone, 0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/focus_screen_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../focus_screen.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/todo/focus_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.workSeconds = 25 * 60,
  });
  final int taskId;
  final String taskTitle;
  final int workSeconds;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  late int _remaining = widget.workSeconds;
  Timer? _timer;
  bool _paused = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _completed) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _complete();
    });
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await ref.read(todoControllerProvider).completeTomato(widget.taskId);
    if (mounted) setState(() => _completed = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _mmss {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: _completed ? _done() : _running(),
        ),
      ),
    );
  }

  Widget _running() {
    final progress =
        widget.workSeconds == 0 ? 0.0 : _remaining / widget.workSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.ink20,
                  valueColor: const AlwaysStoppedAnimation(AppColors.q1),
                ),
              ),
              Text(_mmss,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(widget.taskTitle,
            style:
                const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('放弃'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => setState(() => _paused = !_paused),
              child: Text(_paused ? '继续' : '暂停'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('完成 +1 🍅 · 之后短休 5 分',
            style: TextStyle(fontSize: 11, color: AppColors.ink40)),
      ],
    );
  }

  Widget _done() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍅', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('番茄完成 +1',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('该短休 5 分了 · ${widget.taskTitle}',
            style: TextStyle(fontSize: 13, color: AppColors.ink60)),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/todo/focus_screen_test.dart`
Expected: PASS（注意:第一条用 `pump(Duration(seconds:1))` 推进 `Timer.periodic`;若完成态断言时序略有偏差,微调 `pump` 次数让 timer fire 完、`completeTomato` 的 microtask 跑完。）

- [ ] **Step 5: 提交**

```bash
git add lib/features/todo/focus_screen.dart test/features/todo/focus_screen_test.dart
git commit -m "feat(todo): FocusScreen 番茄专注屏(倒计时/暂停/放弃/完成+🍅)"
```

---

### Task 3: 待办卡显 🍅 + 点击发起番茄

> `TodoCard` 加 `tomatoDone`/`tomatoEst`/`onFocus`;meta 区显一个 `🍅 done[/est]` 按钮,点 → `onFocus`。`TodoScreen` 的 `_card` 传入番茄数 + `onFocus = 推 FocusScreen`。已完成卡不显发起按钮。

**Files:**
- Modify: `lib/features/todo/todo_card.dart`、`lib/features/todo/todo_screen.dart`
- Test: `test/features/todo/todo_card_test.dart`、`test/features/todo/todo_screen_test.dart`

- [ ] **Step 1: 写失败测试(card)**

在 `test/features/todo/todo_card_test.dart` 追加:
```dart
  testWidgets('显示 🍅 数 + 点击发起 onFocus', (tester) async {
    var focused = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodoCard(
          title: '写 Java 代码',
          domain: '工作',
          done: false,
          overdue: false,
          rolloverCount: 0,
          tomatoDone: 1,
          tomatoEst: 3,
          onToggle: () {},
          onFocus: () => focused = true,
        ),
      ),
    ));
    expect(find.textContaining('🍅'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('todo-focus')));
    expect(focused, true);
  });
```
并把 `todo_card_test.dart` 里**已有**两条用例的 `TodoCard(...)` 补上新必填参数 `tomatoDone: 0, tomatoEst: null, onFocus: () {}`(否则编译不过)。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/todo_card_test.dart`
Expected: FAIL（缺参数 / 缺 onFocus / 找不到 🍅）

- [ ] **Step 3: 改 `todo_card.dart`**

给 `TodoCard` 加三个字段:
```dart
  final int tomatoDone;
  final int? tomatoEst;
  final VoidCallback onFocus;
```
并加进构造函数(`required this.tomatoDone, required this.tomatoEst, required this.onFocus,`)。

把 🍅 发起按钮加在**内层 Row**(那个 `Row(crossAxisAlignment: start, children: [IconButton, SizedBox, Expanded(child: Column(...))])`)里、`Expanded(child: Column(...))` **之后**作为末尾子项(该 Row 在外层 `Expanded` 内、宽度已有界,`Expanded[Column]` 自然把 🍅 推到右端,**不需要 Spacer**)。仅未完成显示:
```dart
                    Expanded(child: Column(...)),  // ← 现有,保持不动
                    if (!done) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        key: const ValueKey('todo-focus'),
                        onTap: onFocus,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.q1Tint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              '🍅 $tomatoDone${tomatoEst != null ? '/$tomatoEst' : ''}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.q1)),
                        ),
                      ),
                    ],
```

- [ ] **Step 4: 改 `todo_screen.dart` 传参 + 发起**

`_card(ctl, t, done)` 与 `_pendingTile` 里构造 `TodoCard` 的地方,补:
```dart
        tomatoDone: t.tomatoDone,
        tomatoEst: t.tomatoEst,
        onFocus: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FocusScreen(taskId: t.id, taskTitle: title))),
```
`_card` 需要 `context` —— 把 `_card(ctl, t, done)` 改成 `_card(context, ctl, t, done)` 并在签名加 `BuildContext context`;`title` 用与现有相同的 `(t.currentPromptText?.isNotEmpty ?? false) ? t.currentPromptText! : t.title`。顶部加 `import 'focus_screen.dart';`。

- [ ] **Step 5: 改 todo_screen_test 已有用例(TodoCard 新增必填参数经 _card 透传,屏级测试不直接构造 TodoCard,通常无需改;若编译/断言受影响则跟随修)**

跑全量前先单独跑:
Run: `flutter test test/features/todo/`
Expected: PASS

- [ ] **Step 6: 全量 + analyze + 提交**

Run: `flutter analyze` → 无 issue;`flutter test` → 全绿。

```bash
git add -A
git commit -m "feat(todo): 待办卡显 🍅 + 点击发起番茄(进 FocusScreen)"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- `Tasks` 有 `tomatoEst`/`tomatoDone`(v3 迁移);待办卡显 `🍅 done[/est]` 可点 → 进专注屏。
- 专注屏:25 分倒计时环 + 任务名 + 暂停/放弃;到点 → +1 🍅 + 完成态(短休 5 分提示)→ 返回;放弃不计数。
- 未引入 AI 估🍅/喂诊断、积分、自动休息循环、桌面番茄。

## 衔接下一计划

Plan 1.7 正反馈积分(捕获 +2 / 完成 / 番茄 +10,StatsChip 加 ★总积分 + 攒分动画;积分存 prefs/汇总);之后 MAP 诊断标签(AI 异步,含🍅估)+ 提示横幅、复盘(数据分析 + 日历切换 + AI,含番茄会话聚合)。
