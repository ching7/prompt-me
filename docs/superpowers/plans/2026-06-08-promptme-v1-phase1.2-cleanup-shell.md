# PromptMe v1 · 阶段 1.2 清理遗留 + 3-Tab 骨架 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 删掉日历订阅、飞书导入、四象限三套遗留功能(代码 + 测试),把入口从单屏 `TodayScreen` 换成 **3-Tab 骨架**(收件箱 / 待办 / 复盘,底部导航 + 占位屏),app 能编译运行、`flutter analyze` 干净、未删除的测试仍绿。

**Architecture:** 删除类任务无法 TDD——其「验证」是 `flutter analyze` 无错 + 残留测试仍通过。先删日历、再删飞书、再删四象限与旧今日聚合,逐步解开 `database`/`providers`/`integration_providers`/`settings_controller`/`settings_screen` 的引用;最后搭一个 `HomeShell`(BottomNavigationBar + IndexedStack)+ 三个占位屏(收件箱/待办/复盘),骨架用 widget 测试 TDD。**保留**:`Tasks.quadrant` 列与 `Quadrant` 枚举(Tasks 表仍引用、避免迁移)、`TaskSource.feishu` 枚举值(intEnum 索引稳定)、日历表 `Subscriptions`/`CalendarEvents`(无 DAO 的死表,不 drop、不迁移)、fogg 的 `streak_calculator`/`downgrade`、AI、通知、`features/today/widgets/` 里可复用的卡片类组件(留给 Plan 1.3/1.4 接线)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;drift 2.33 + drift_dev;flutter_riverpod 3.x;flutter_test。

**工程根:** 所有路径与命令在 `frontend/promptme-app/` 下。前置:Plan 1.1(分支 `feat/v1-phase1.1-data-foundation`)已落地;本计划在同一分支续做。

**引用关系图(已勘定,供删除时核对):**
- 日历链:`data/daos/calendar_dao.dart(.g)`、`services/calendar_subscription_service.dart`、`domain/parsing/ics_parser.dart`、`domain/parsing/parsed_event.dart`、`domain/fogg/today_aggregator.dart` ← 被 `data/database.dart`、`state/providers.dart`、`state/integration_providers.dart`、`state/settings_controller.dart`、`features/settings/settings_screen.dart`、`features/today/today_screen.dart`、`features/today/widgets/schedule_section.dart` 引用;测试:`test/data/calendar_dao_test.dart`、`test/domain/parsing/ics_parser_test.dart`、`test/services/calendar_subscription_service_test.dart`、`test/domain/fogg/today_aggregator_test.dart`。
- 飞书链:`domain/import/feishu_importer.dart`、`domain/parsing/feishu_markdown_parser.dart`、`domain/parsing/parsed_task.dart`(确认仅飞书用后删)、`features/settings/feishu_import_sheet.dart` ← 被 `features/settings/settings_screen.dart` 引用;测试:`test/domain/import/feishu_importer_test.dart`、`test/domain/parsing/feishu_markdown_parser_test.dart`。
- 四象限:`features/today/widgets/quadrant_section.dart` ← 被 `features/today/today_screen.dart` 引用。
- `features/today/today_screen.dart` 整屏被骨架取代;测试 `test/features/today/today_screen_test.dart`、`test/widget_test.dart`(启动到 TodayScreen)随之删/改。

---

### Task 1: 删日历链 + 解耦 database / providers / integration_providers

**Files:**
- Delete: `lib/data/daos/calendar_dao.dart`、`lib/data/daos/calendar_dao.g.dart`、`lib/services/calendar_subscription_service.dart`、`lib/domain/parsing/ics_parser.dart`、`lib/domain/parsing/parsed_event.dart`、`lib/domain/fogg/today_aggregator.dart`
- Delete: `test/data/calendar_dao_test.dart`、`test/domain/parsing/ics_parser_test.dart`、`test/services/calendar_subscription_service_test.dart`、`test/domain/fogg/today_aggregator_test.dart`
- Modify: `lib/data/database.dart`、`lib/state/providers.dart`、`lib/state/integration_providers.dart`
- Regenerate: `lib/data/database.g.dart`

- [ ] **Step 1: 删日历相关文件**

```bash
git rm lib/data/daos/calendar_dao.dart lib/data/daos/calendar_dao.g.dart \
  lib/services/calendar_subscription_service.dart \
  lib/domain/parsing/ics_parser.dart lib/domain/parsing/parsed_event.dart \
  lib/domain/fogg/today_aggregator.dart \
  test/data/calendar_dao_test.dart test/domain/parsing/ics_parser_test.dart \
  test/services/calendar_subscription_service_test.dart \
  test/domain/fogg/today_aggregator_test.dart
```

- [ ] **Step 2: `database.dart` 移除 CalendarDao(保留日历表为死表)**

`lib/data/database.dart`:删掉 `import 'daos/calendar_dao.dart';`(第 9 行);把 `@DriftDatabase` 的 `daos:` 从 `[TaskDao, TaskEventDao, CalendarDao]` 改成 `[TaskDao, TaskEventDao]`。**保留** `Subscriptions`/`CalendarEvents` 两个表定义与 `tables:` 列表(无 DAO 的死表,不动、不迁移)。

- [ ] **Step 3: `providers.dart` 删日历相关 Provider、重写 streakProvider**

`lib/state/providers.dart`:删除 `rowToTodayEvent`、`todayViewProvider`、`subscriptionsProvider` 三者,以及顶部 `import '../domain/fogg/today_aggregator.dart';`。`streakProvider` 原先 `ref.watch(todayViewProvider)` 触发重算,改成监听今日任务流:

```dart
final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  ref.watch(_todayTasksProvider); // 任务变化时重算
  final days = await db.taskDao.completionDays();
  return StreakCalculator.currentStreak(days, date);
});

// 仅监听今日任务表，替代旧 todayViewProvider 的刷新作用。
final _todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.taskDao.watchTasksForDate(date);
});
```

`rowToTodayTask` 暂时保留(无害);若 analyze 报「未使用」,一并删掉它和 `import '../domain/enums.dart';`(按 analyze 提示决定)。

- [ ] **Step 4: `integration_providers.dart` 删订阅服务 Provider**

`lib/state/integration_providers.dart`:删除 `subscriptionServiceProvider` 及顶部 `import '../services/calendar_subscription_service.dart';`。其余(sharedPrefs/settings/aiClient/notification)保留。

- [ ] **Step 5: 重新生成 drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 成功;`database.g.dart` 不再含 `CalendarDao` 访问器(日历表的生成代码仍在,因表保留)。

- [ ] **Step 6: 编译核验**

Run: `flutter analyze`
Expected: 无 error。(此时 `today_screen.dart`/`settings_screen.dart` 仍引用已删的日历符号 → **会报错**;若 analyze 在这两文件报日历相关错,属预期,Task 3/4 会清掉它们。先确认报错**仅集中在这两文件 + 日历符号**,不是别处连带坏掉。)

> 说明:本 Task 故意先不动 today_screen/settings_screen,把它们留到 Task 3/4 一起处理。Step 6 只用来确认「除这两文件外,日历删除没有连带破坏」。

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "refactor: 删日历链(dao/service/ics/聚合)+ 解耦 providers/database"
```

---

### Task 2: 删飞书链 + 清 settings_screen 飞书部分

**Files:**
- Delete: `lib/domain/import/feishu_importer.dart`、`lib/domain/parsing/feishu_markdown_parser.dart`、`lib/features/settings/feishu_import_sheet.dart`、`test/domain/import/feishu_importer_test.dart`、`test/domain/parsing/feishu_markdown_parser_test.dart`
- Conditionally delete: `lib/domain/parsing/parsed_task.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: 确认 parsed_task 仅飞书用**

Run: `grep -rn "parsed_task\|ParsedTask" lib test`
若除 `feishu_markdown_parser.dart` / `feishu_importer.dart` / `parsed_task.dart` 自身外**无其它引用**,则它仅服务飞书,可删;否则保留它,只删其余飞书文件。

- [ ] **Step 2: 删飞书文件**

```bash
git rm lib/domain/import/feishu_importer.dart \
  lib/domain/parsing/feishu_markdown_parser.dart \
  lib/features/settings/feishu_import_sheet.dart \
  test/domain/import/feishu_importer_test.dart \
  test/domain/parsing/feishu_markdown_parser_test.dart
# 若 Step 1 判定 parsed_task 仅飞书用：
git rm lib/domain/parsing/parsed_task.dart
```

- [ ] **Step 3: `settings_screen.dart` 去飞书**

读 `lib/features/settings/settings_screen.dart`,删除:`import '...feishu_import_sheet.dart';`、任何打开 `FeishuImportSheet` 的入口/按钮/卡片、以及只为飞书存在的辅助代码。保留 AI 配置部分。改完该文件应不再出现 `feishu`/`Feishu`/`FeishuImportSheet` 字样。

- [ ] **Step 4: 编译核验**

Run: `flutter analyze`
Expected: settings_screen 不再有飞书相关错误(日历相关错误仍可能存在 → Task 3 清);确认没有新引入的别处错误。

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "refactor: 删飞书链(importer/parser/sheet)+ 清 settings 飞书入口"
```

---

### Task 3: 删四象限 + 清 settings 日历设置 + 清 settings_screen 日历部分 + 删 today 旧屏

**Files:**
- Delete: `lib/features/today/widgets/quadrant_section.dart`、`lib/features/today/widgets/schedule_section.dart`、`lib/features/today/today_screen.dart`、`test/features/today/today_screen_test.dart`
- Modify: `lib/state/settings_controller.dart`、`lib/features/settings/settings_screen.dart`

- [ ] **Step 1: 删四象限/日程组件 + 旧今日屏 + 其测试**

```bash
git rm lib/features/today/widgets/quadrant_section.dart \
  lib/features/today/widgets/schedule_section.dart \
  lib/features/today/today_screen.dart \
  test/features/today/today_screen_test.dart
```

> 保留 `features/today/widgets/` 下其余组件(`task_card.dart`/`add_task_sheet.dart`/`celebration_overlay.dart`/`ai_panel.dart`/`too_hard_sheet.dart`/`stats_header.dart`)——Plan 1.3/1.4 复用。

- [ ] **Step 2: `settings_controller.dart` 去日历订阅设置**

`lib/state/settings_controller.dart`:删除 `static const _kSubUrl = 'subscription_url';`、`pendingSubscriptionUrl` getter、`saveSubscriptionUrl` 方法。保留 AI 部分。

- [ ] **Step 3: `settings_screen.dart` 去日历订阅**

`lib/features/settings/settings_screen.dart`:删除日历订阅相关 UI(订阅 URL 输入、`saveSubscriptionUrl`/`pendingSubscriptionUrl`/`subscriptionServiceProvider` 的调用、对应 import)。保留 AI 配置。改完该文件应不再出现 `subscription`/`calendar`/`Calendar` 字样。

- [ ] **Step 4: 编译核验**

Run: `flutter analyze`
Expected: **无 error**(此时 `app.dart` 仍 `home: TodayScreen()` 但 today_screen 已删 → app.dart 报错,Task 4 修;先确认除 app.dart 外无其它残留错误)。

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "refactor: 删四象限/日程组件 + 旧今日屏 + 清 settings 日历设置"
```

---

### Task 4: 3-Tab 骨架 `HomeShell` + 三占位屏(TDD)

**Files:**
- Create: `lib/features/shell/home_shell.dart`、`lib/features/shell/placeholder_screens.dart`
- Modify: `lib/app.dart`
- Test: `test/features/shell/home_shell_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/features/shell/home_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/shell/home_shell.dart';

void main() {
  testWidgets('三 Tab 默认在待办、可切到收件箱与复盘', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    // 底部三个 Tab 标签都在
    expect(find.text('收件箱'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);

    // 默认选中「待办」→ 待办占位屏标题可见
    expect(find.text('待办 · 占位'), findsOneWidget);

    // 切到收件箱
    await tester.tap(find.text('收件箱'));
    await tester.pumpAndSettle();
    expect(find.text('收件箱 · 占位'), findsOneWidget);

    // 切到复盘
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('复盘 · 占位'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/shell/home_shell_test.dart`
Expected: FAIL —「Target of URI doesn't exist: '.../home_shell.dart'」

- [ ] **Step 3: 写占位屏**

新建 `lib/features/shell/placeholder_screens.dart`:

```dart
import 'package:flutter/material.dart';

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$label · 占位', style: const TextStyle(fontSize: 18)));
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('收件箱');
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('待办');
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('复盘');
}
```

- [ ] **Step 4: 写 HomeShell**

新建 `lib/features/shell/home_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'placeholder_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // 默认「待办」

  static const _screens = [InboxScreen(), TodoScreen(), ReviewScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: '收件箱'),
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: '待办'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: '复盘'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/shell/home_shell_test.dart`
Expected: PASS

- [ ] **Step 6: `app.dart` 接入骨架**

`lib/app.dart`:把 `import 'features/today/today_screen.dart';` 改成 `import 'features/shell/home_shell.dart';`,`home: const TodayScreen()` 改成 `home: const HomeShell()`。

- [ ] **Step 7: 全量编译 + 测试**

Run: `flutter analyze`
Expected: **无 issue**(app.dart 已不再引用已删屏)。

Run: `flutter test`
Expected: 全绿——剩余的 `test/widget_test.dart` 仍启动旧 `TodayScreen` 会失败 → 见 Step 8 修。

- [ ] **Step 8: 改 `widget_test.dart` 启动骨架**

读 `test/widget_test.dart`,把它对 `PromptMeApp`/`TodayScreen` 的启动断言改成验证 `HomeShell` 启动(例如 `expect(find.text('待办 · 占位'), findsOneWidget);`)。若该测试强依赖被删的 provider/DB,改成最小化:pump `MaterialApp(home: HomeShell())` 断言三 Tab 存在。

Run: `flutter test`
Expected: **全绿**。

- [ ] **Step 9: 提交**

```bash
git add -A
git commit -m "feat(shell): 3-Tab 骨架 HomeShell(收件箱/待办/复盘)+ app 接入"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- 日历订阅 / 飞书导入 / 四象限的 lib 与 test 代码已删净(`grep -rn "calendar\|feishu\|quadrant_section\|Subscription\b" lib` 仅余:保留的日历死表定义、`Quadrant` 枚举/列)。
- app 启动到 `HomeShell`,底部三 Tab(收件箱/待办/复盘)可切换。
- 保留:`Quadrant` 枚举与 `Tasks.quadrant` 列、`TaskSource.feishu` 值、日历死表、fogg streak/downgrade、AI、通知、`features/today/widgets/` 可复用组件、Plan 1.1 的数据层方法。

## 衔接下一计划

Plan 1.3(收件箱 + 待办 GTD):把占位屏换成真实屏——收件箱(`watchInbox` + 手记 + 标签 + 过滤 + 一键加入今日)、待办(GTD 智能清单 + 领域色标 + 面包屑 + MAP 标签 + 逾期 + FAB + 积分 chip),复用 `features/today/widgets/` 组件与 Plan 1.1 的 DAO 方法,并新增待办所需的 provider(替代已删的 `todayViewProvider`)。
