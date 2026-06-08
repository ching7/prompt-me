# PromptMe v1 · 阶段 1.5 福格闭环 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给待办屏的今日任务卡加上福格闭环:**左滑「我做到了」→ 完成 + 全屏庆祝**;**右滑「太难了」→ 压缩版 P/A/M 小 sheet → 无底线降级**(任务缩成 2 分钟微习惯,卡片标题变微习惯文案,并刷到锁屏通知)。

**Architecture:** 复用现成件:`TodayController.complete`(完成+记事件)、`TodayController.tooHard(id, reason)`(AI/本地兜底降级 + 写 currentPromptText/level + 记事件 + 锁屏通知,已有)、`CelebrationOverlay`(`lib/features/today/widgets/celebration_overlay.dart`,彩纸庆祝,`streak`+`onDismiss`)、`FailureReason`(forgot/tired/noMotivation → P/A/M)。待办卡 `currentPromptText` 非空时已显示微习惯文案(Plan 1.4 的 `_card` 已处理),所以降级后卡片自动变样。新增:压缩版 `TooHardSheet`(P/A/M chip);在 `TodoScreen` 把今日待办的卡包进 `Dismissible`(左滑完成 / 右滑太难)。

**范围边界(不做):** 番茄钟、积分、MAP 诊断标签、复盘(各自后续计划)。微习惯的「锁屏卡」UI 不在 app 内做(`tooHard` 已触发系统通知 `showMicroHabit`,真机可见)。已完成卡不加滑动(点圆圈重开,Plan 1.4 已有)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;drift 2.33;confetti 0.8;flutter_test。

**工程根:** `frontend/promptme-app/`。前置:Plan 1.1–1.4 已在 master。本计划在新分支 `feat/v1-phase1.5-fogg` 上做。

**⚠️ 跑测试/analyze 必带前缀**(国内代理坑,否则 flutter_tester 连 localhost 被重置全崩):
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
下文命令隐含已 export。**别 `flutter clean`**(清掉已缓存 sqlite3 `.so`)。

**视觉参照:** 原型 `...promptme-v1-mockup.html` 第 ⑥ 屏(太难了压缩版:一句话标题 + 一行 P/A/M chip)、第 ⑦ 屏(微习惯)、第 ⑧ 屏(庆祝)。

---

### Task 1: 压缩版 `TooHardSheet`(P/A/M chip)

> 底部小 sheet:标题「太难了？我帮你变小」+ 一句「卡在哪——把「<任务>」降到 2 分钟」+ 一行三个 chip(忘记了🌫️P / 太累了🪫A / 没动力🫥M)。点 chip → `onReason(FailureReason)`。回调式,便于测试。

**Files:**
- Create: `lib/features/todo/too_hard_sheet.dart`
- Test: `test/features/todo/too_hard_sheet_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/todo/too_hard_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/todo/too_hard_sheet.dart';

void main() {
  testWidgets('点「太累了」回调 FailureReason.tired', (tester) async {
    FailureReason? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TooHardSheet(
          taskTitle: '写 Java 代码',
          onReason: (r) => got = r,
        ),
      ),
    ));
    expect(find.textContaining('太难了'), findsOneWidget);
    expect(find.textContaining('写 Java 代码'), findsOneWidget);
    await tester.tap(find.text('太累了'));
    await tester.pump();
    expect(got, FailureReason.tired);
  });

  testWidgets('三个原因都在', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TooHardSheet(taskTitle: 'x', onReason: (_) {}),
      ),
    ));
    expect(find.text('忘记了'), findsOneWidget);
    expect(find.text('太累了'), findsOneWidget);
    expect(find.text('没动力'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/too_hard_sheet_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../too_hard_sheet.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/features/todo/too_hard_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';

/// 压缩版「太难了」：一句话标题 + 一行 P/A/M chip → onReason。
class TooHardSheet extends StatelessWidget {
  const TooHardSheet(
      {super.key, required this.taskTitle, required this.onReason});
  final String taskTitle;
  final void Function(FailureReason) onReason;

  static const _reasons = [
    (FailureReason.forgot, '🌫️', '忘记了', 'P · 提示'),
    (FailureReason.tired, '🪫', '太累了', 'A · 精力'),
    (FailureReason.noMotivation, '🫥', '没动力', 'M · 动机'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.ink20,
                borderRadius: BorderRadius.circular(5)),
          ),
          const Text('太难了？我帮你变小',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Text('卡在哪——把「$taskTitle」降到 2 分钟：',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink60)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final r in _reasons)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: _chip(r.$1, r.$2, r.$3, r.$4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(FailureReason reason, String ic, String label, String tag) {
    return InkWell(
      onTap: () => onReason(reason),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 13, 6, 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.ink20, width: 1.5),
        ),
        child: Column(
          children: [
            Text(ic, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(tag,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink40)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/todo/too_hard_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/todo/too_hard_sheet.dart test/features/todo/too_hard_sheet_test.dart
git commit -m "feat(todo): 压缩版 TooHardSheet(P/A/M chip)"
```

---

### Task 2: 待办卡滑动闭环(左滑完成+庆祝 / 右滑太难了→降级)

> 在 `TodoScreen` 把**今日待办(pending)**的卡包进 `Dismissible`:左滑(endToStart)=我做到了 → `complete` + 弹 `CelebrationOverlay`;右滑(startToEnd)=太难了 → 弹 `TooHardSheet` → 选原因 → `tooHard`(降级,卡片标题经 stream 变微习惯)。已完成卡不变(点圆圈重开)。

**Files:**
- Modify: `lib/features/todo/todo_screen.dart`
- Test: `test/features/todo/todo_screen_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/features/todo/todo_screen_test.dart` 的 `main()` 内追加(沿用文件已有的 `UncontrolledProviderScope` + 内存 DB 写法):

```dart
  testWidgets('右滑太难了 → 弹 sheet → 选原因 → 任务降级(标题变微习惯)', (tester) async {
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

    // 右滑(startToEnd)— fling 更可靠触发 Dismissible
    await tester.fling(find.text('写 Java 代码'), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('太难了'), findsOneWidget); // sheet 出现

    await tester.tap(find.text('太累了'));
    await tester.pumpAndSettle();

    // 降级后原标题不再出现(被微习惯文案替代)
    expect(find.text('写 Java 代码'), findsNothing);
  });

  testWidgets('左滑我做到了 → 完成 + 庆祝,任务进已完成', (tester) async {
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

    // 左滑(endToStart)— fling 触发;庆祝有彩纸动画,用 pump(时长) 不用 pumpAndSettle(否则可能挂)
    await tester.fling(find.text('A'), const Offset(-400, 0), 1000);
    await tester.pump(); // 触发 confirmDismiss
    await tester.pump(const Duration(milliseconds: 600)); // 完成 + 庆祝弹出
    expect(find.textContaining('做到了'), findsOneWidget); // 庆祝层
    await tester.pump(const Duration(seconds: 2)); // CelebrationOverlay 1.9s 自动消失定时器
    await tester.pump(const Duration(milliseconds: 600));
    // 任务已进「已完成」
    expect(find.textContaining('已完成'), findsOneWidget);
  });
```

> 注:`tooHard` 路径会读 `aiClientProvider`(测试中 AI 未配置 → 走 `Downgrade.localFallback`)与 `notificationServiceProvider`(测试中未 override → 抛错被 `TodayController.tooHard` 的 try/catch 吞掉),均无需在测试里 override。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/todo_screen_test.dart`
Expected: FAIL（新两条找不到 sheet / 庆祝,因 TodoScreen 还没加 Dismissible）

- [ ] **Step 3: 改 `todo_screen.dart`**

`lib/features/todo/todo_screen.dart`:

(a) 顶部加 import:
```dart
import '../../domain/enums.dart';
import '../today/widgets/celebration_overlay.dart';
import 'too_hard_sheet.dart';
```

(b) `build` 里取 streak 已有(`final streak = ...`)。新增两个方法到 `TodoScreen` 类:
```dart
  void _celebrate(BuildContext context, int streak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CelebrationOverlay(
        streak: streak,
        onDismiss: () => Navigator.of(ctx).maybePop(),
      ),
    );
  }

  Future<FailureReason?> _askReason(BuildContext context, String title) {
    return showModalBottomSheet<FailureReason>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TooHardSheet(
        taskTitle: title,
        onReason: (r) => Navigator.of(context).pop(r),
      ),
    );
  }
```

(c) 把**今日待办**的卡(pending,`_card(ctl, t, false)`)包进 `Dismissible`。在 `data:` 闭包里,`for (final t in view.pending)` 那行改成调用一个新 helper `_pendingTile(context, ctl, t, streak)`,并新增该 helper:
```dart
  Widget _pendingTile(
      BuildContext context, TodoController ctl, Task t, int streak) {
    final title = (t.currentPromptText?.isNotEmpty ?? false)
        ? t.currentPromptText!
        : t.title;
    return Dismissible(
      key: ValueKey('todo-${t.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        color: AppColors.q3, // 右滑 → 太难了
        padding: const EdgeInsets.only(left: 20),
        child: const Text('太难了',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        color: AppColors.leaf, // 左滑 → 我做到了
        padding: const EdgeInsets.only(right: 20),
        child: const Text('我做到了 ✓',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          await ctl.complete(t.id);
          if (context.mounted) _celebrate(context, streak);
          return true; // 从今日待办移除（stream 会把它放进已完成）
        } else {
          final reason = await _askReason(context, title);
          if (reason != null) await ctl.tooHard(t.id, reason);
          return false; // 不移除：降级后卡片经 stream 变微习惯
        }
      },
      child: _card(ctl, t, false),
    );
  }
```
并把 `for (final t in view.pending) _card(ctl, t, false),` 改为 `for (final t in view.pending) _pendingTile(context, ctl, t, streak),`。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/todo/todo_screen_test.dart`
Expected: PASS（原 2 条 + 新 2 条）

- [ ] **Step 5: 全量回归 + analyze + 提交**

Run: `flutter analyze` → 无 issue;`flutter test` → 全绿。

```bash
git add -A
git commit -m "feat(todo): 福格闭环——左滑完成+庆祝 / 右滑太难了→降级微习惯"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- 今日待办卡**左滑**=我做到了 → 完成 + 全屏庆祝(彩纸 + 🔥连续天数 + 「做到了。这就是积累」,约 2 秒自动消失)→ 任务进已完成。
- 今日待办卡**右滑**=太难了 → 压缩版 P/A/M 小 sheet → 选原因 → 任务降级(卡片标题变 2 分钟微习惯文案;真机另触发锁屏通知)。
- 复用 `TodayController.complete/tooHard` + `CelebrationOverlay`;新增 `TooHardSheet`。
- 未引入番茄/积分/MAP/复盘。

## 衔接下一计划

Plan 1.6 番茄钟(专注屏 + 每任务 🍅 预估/已完成 + 完成庆祝 + 暂停/放弃);之后 1.7 正反馈积分(捕获+2/完成/番茄,StatsChip 加 ★总积分 + 跳动动画)、1.8 MAP 诊断标签(AI 异步)+ 提示横幅、1.9 复盘(数据分析 + 日历切换 + AI)。
