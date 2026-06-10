# PromptMe v1 · 阶段 1.7 正反馈积分实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把每个正向动作即时兑现成「总积分」:**捕获 +2 · 完成任务 +10 · 番茄完成 +10**(无连击加成)。右上角 `StatsChip` 加 `★总积分`,**响应式即时跳**;完成 / 番茄完成时庆祝处显示 `+N 分`。捕获不弹动画(捕获后 sheet 即关),只静默攒分。

**Architecture（事件派生,单一真相源）:** 积分**不存可变计数器**,而是从 `TaskEvents` 事件流**派生求和**——和阶段 1.4 的 streak 同一套响应式模式,可审计、可重放,天然兼容阶段② 桌面双向同步对账。

- `TaskEventType` 在**末尾**追加 `capture`、`tomato`(现有 `done`=0/`tooHard`=1 不动,intEnum 存 index,新值 =2/3,**无需 schema 迁移**——`TaskEvents.type` 是既有 int 列)。
- `TaskDao` 的 `@DriftAccessor` 加入 `TaskEvents`,在 **DAO 层单点记事件**:`insertCapture` 落 `capture` 事件(收件箱 `+` 与「加入今日」两个入口都走它,单点全覆盖)、`incrementTomato` 落 `tomato` 事件。`done`/`tooHard` 维持现有在 `TodayController` 记录不变。
- 新建纯域 `lib/domain/score/score_calculator.dart`:`ScoreCalculator.total(types)` = `capture×2 + done×10 + tomato×10`(`tooHard` 计 0)。常量集中在此,便于调值。
- `TaskEventDao` 加 `watchAll()` 流;`pointsProvider`(StreamProvider)`watchAll → map(types) → ScoreCalculator.total`;`TodoController.currentPoints()` 即时读(庆祝「+N 分」用,避免读旧值,同 `currentStreak`)。
- `StatsChip` 加 `points` 入参显 `★N`;`CelebrationOverlay` 加可选 `pointsDelta` 显 `+N 分`;`FocusScreen` 完成态加 `+10 分`。

**范围边界（不做）:** 连击加成 / 难度加权(本期定死三档常量)；捕获浮「+2」动画(捕获后 sheet 关,只静默攒分)；数字滚动/彩纸印章等重动画(本期轻量:chip 响应式即时跳 + 弹层「+N 分」文字)；积分历史曲线 / 复盘里的积分聚合(复盘计划再做)；桌面端积分跳动(阶段②)。**历史数据说明:** 既有 `done` 事件会回算 +10/条(是真实成就,保留);番茄/捕获事件本期才引入,**仅新动作计分**,旧 `tomatoDone` 累计与上线前的捕获不补记。

**Tech Stack:** Flutter 3.44 / Dart 3.12;flutter_riverpod 3.x;drift 2.33;flutter_test。

**工程根:** `frontend/promptme-app/`。前置:Plan 1.1–1.6 已在 master。本计划在新分支 `feat/v1-phase1.7-score` 上做。

**⚠️ 跑测试/analyze 必带前缀**(国内代理坑):
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
下文命令隐含已 export。**别 `flutter clean`**(清掉已缓存 sqlite3 `.so`)。drift 改表/改 accessor 后跑 `dart run build_runner build --delete-conflicting-outputs`。

**视觉参照:** 原型右上角紧凑 chip(🔥连续 │ ◎今日完成 │ ★总积分);完成/番茄庆祝处 +N 分跳动。

---

### Task 1: 事件类型 capture/tomato + DAO 单点记事件 + ScoreCalculator(纯域)

**Files:**
- Modify: `lib/domain/enums.dart`、`lib/data/daos/task_dao.dart`、`lib/data/daos/task_event_dao.dart`
- Create: `lib/domain/score/score_calculator.dart`
- Regenerate: `lib/data/daos/task_dao.g.dart`、`lib/data/daos/task_event_dao.g.dart`(及 `database.g.dart` 若受影响)
- Test: `test/domain/score/score_calculator_test.dart`、`test/data/task_dao_test.dart`

- [ ] **Step 1: 写失败测试(纯域计算器)**

新建 `test/domain/score/score_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/score/score_calculator.dart';

void main() {
  test('捕获+2 · 完成+10 · 番茄+10 · 太难了不计分', () {
    final types = [
      TaskEventType.capture, // +2
      TaskEventType.capture, // +2
      TaskEventType.done,    // +10
      TaskEventType.tomato,  // +10
      TaskEventType.tooHard, // +0
    ];
    expect(ScoreCalculator.total(types), 24);
  });

  test('空事件 = 0 分', () {
    expect(ScoreCalculator.total(const []), 0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/score/score_calculator_test.dart`
Expected: FAIL —「Target of URI doesn't exist / capture isn't defined」

- [ ] **Step 3: 加枚举值 + 写计算器**

`lib/domain/enums.dart`,把 `TaskEventType` 改成(**末尾追加,顺序不能动**):
```dart
enum TaskEventType { done, tooHard, capture, tomato }
```

新建 `lib/domain/score/score_calculator.dart`:
```dart
import '../enums.dart';

/// 总积分 = 各正向事件求和(纯函数,事件派生的单一真相源)。
/// 数值集中在此,便于后续调档 / 加连击加成。
class ScoreCalculator {
  static const int capturePoints = 2;
  static const int donePoints = 10;
  static const int tomatoPoints = 10;

  static int pointsFor(TaskEventType type) => switch (type) {
        TaskEventType.capture => capturePoints,
        TaskEventType.done => donePoints,
        TaskEventType.tomato => tomatoPoints,
        TaskEventType.tooHard => 0,
      };

  static int total(Iterable<TaskEventType> types) =>
      types.fold(0, (sum, t) => sum + pointsFor(t));
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/score/score_calculator_test.dart`
Expected: PASS

- [ ] **Step 5: 写失败测试(DAO 落事件)**

在 `test/data/task_dao_test.dart` 的 `main()` 内追加:
```dart
test('捕获落 capture 事件、番茄落 tomato 事件', () async {
  final id = await db.taskDao.insertCapture(title: '写 Java 代码', domain: '工作');
  await db.taskDao.incrementTomato(id);

  final events = await db.taskEventDao.all();
  final types = events.map((e) => e.type).toList();
  expect(types, contains(TaskEventType.capture));
  expect(types, contains(TaskEventType.tomato));
});
```
（顶部若缺则补 `import 'package:promptme/domain/enums.dart';`。）

- [ ] **Step 6: 跑测试确认失败**

Run: `flutter test test/data/task_dao_test.dart`
Expected: FAIL（事件表里没有 capture/tomato 记录）

- [ ] **Step 7: DAO accessor 加 TaskEvents + 记事件 + watchAll**

`lib/data/daos/task_dao.dart`:把 accessor 改为
```dart
@DriftAccessor(tables: [Tasks, TaskEvents])
```
`insertCapture` 改成 async、插入后记 `capture` 事件并返回 id:
```dart
  Future<int> insertCapture({
    required String title,
    String? domain,
    DateTime? scheduledDate,
  }) async {
    final id = await into(tasks).insert(TasksCompanion.insert(
      title: title,
      quadrant: Quadrant.importantUrgent, // 占位，UI 不用
      source: TaskSource.capture,
      domain: Value(domain),
      scheduledDate: Value(scheduledDate),
    ));
    await into(taskEvents).insert(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.capture,
      createdAt: DateTime.now(),
    ));
    return id;
  }
```
`incrementTomato` 末尾追加记 `tomato` 事件:
```dart
  Future<void> incrementTomato(int id) async {
    final t = await getById(id);
    await (update(tasks)..where((x) => x.id.equals(id)))
        .write(TasksCompanion(tomatoDone: Value((t?.tomatoDone ?? 0) + 1)));
    await into(taskEvents).insert(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.tomato,
      createdAt: DateTime.now(),
    ));
  }
```
> `TaskEventsCompanion.insert` 必填字段以现有 `today_controller.dart` 里的用法为准(`taskId`/`type`/`createdAt`);`reason`/`microVersionText` 可空不传。

`lib/data/daos/task_event_dao.dart` 加流(`pointsProvider` 用):
```dart
  Stream<List<TaskEvent>> watchAll() => select(taskEvents).watch();
```

- [ ] **Step 8: 重新生成 drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成成功(TaskDao 的 mixin 现含 `taskEvents`)。

- [ ] **Step 9: 跑测试确认通过**

Run: `flutter test test/data/task_dao_test.dart test/domain/score/score_calculator_test.dart`
Expected: PASS

- [ ] **Step 10: 提交**

```bash
git add lib/domain/enums.dart lib/domain/score/ lib/data/daos/ test/domain/score/ test/data/task_dao_test.dart
git commit -m "feat(score): TaskEventType.capture/tomato + DAO 单点记事件 + ScoreCalculator(事件派生总积分)"
```

---

### Task 2: pointsProvider + currentPoints + StatsChip ★总积分

> 积分流 → chip 即时显 `★N`。`pointsProvider` 从 `watchAll` 派生;`StatsChip` 加 `points`;`TodoScreen` 读流喂进去。`TodoController.currentPoints()` 即时读供庆祝用(Task 3)。

**Files:**
- Modify: `lib/state/providers.dart`、`lib/state/todo_controller.dart`、`lib/features/todo/stats_chip.dart`、`lib/features/todo/todo_screen.dart`
- Test: `test/features/todo/stats_chip_test.dart`(新建或追加)、`test/state/`(若有 provider 测试则追加)

- [ ] **Step 1: 写失败测试(StatsChip 显 ★积分)**

新建/追加 `test/features/todo/stats_chip_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/todo/stats_chip.dart';

void main() {
  testWidgets('显示 🔥连续 / ◎完成 / ★总积分', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatsChip(streak: 3, done: 2, total: 5, points: 42),
      ),
    ));
    expect(find.textContaining('🔥3'), findsOneWidget);
    expect(find.textContaining('2/5'), findsOneWidget);
    expect(find.textContaining('★42'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/todo/stats_chip_test.dart`
Expected: FAIL（`points` 命名参数不存在 / 找不到 ★42）

- [ ] **Step 3: StatsChip 加 points**

`lib/features/todo/stats_chip.dart`:构造函数加 `required this.points`、字段 `final int points;`,在 `◎done/total` 后加分隔与 `★points`:
```dart
        _sep(),
        Text('★$points',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.pop)),
```
（`AppColors.pop` 不存在就用 `AppColors.q1`,与项目其它强调色一致。)

- [ ] **Step 4: pointsProvider + currentPoints**

`lib/state/providers.dart` 追加(`streakProvider` 旁):
```dart
// 流式总积分:任意正向事件即时重算。
final pointsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.taskEventDao
      .watchAll()
      .map((events) => ScoreCalculator.total(events.map((e) => e.type)));
});
```
顶部加 `import '../domain/score/score_calculator.dart';`。

`lib/state/todo_controller.dart` 的 `TodoController` 加(供 Task 3 庆祝即时读):
```dart
  /// 即时读总积分(庆祝「+N 分」后显示总分用,避免读旧值)。
  Future<int> currentPoints() async {
    final events = await _db.taskEventDao.all();
    return ScoreCalculator.total(events.map((e) => e.type));
  }
```
顶部加 `import '../domain/score/score_calculator.dart';`。

- [ ] **Step 5: TodoScreen 喂 points**

`lib/features/todo/todo_screen.dart` 的 `build` 内,`streak` 旁加:
```dart
    final points = ref.watch(pointsProvider).value ?? 0;
```
`StatsChip(...)` 调用补 `points: points,`。

- [ ] **Step 6: 跑测试 + analyze**

Run: `flutter test test/features/todo/` → PASS;`flutter analyze lib` → 无 issue。
> 既有 `todo_screen` 屏级测试若因 `StatsChip` 新必填 `points` 编译失败:`StatsChip` 由 `TodoScreen` 内部构造、测试不直接 new 它,通常不受影响;真受影响则跟随补 `points`。

- [ ] **Step 7: 提交**

```bash
git add lib/state/providers.dart lib/state/todo_controller.dart lib/features/todo/stats_chip.dart lib/features/todo/todo_screen.dart test/features/todo/stats_chip_test.dart
git commit -m "feat(score): pointsProvider 流式总积分 + StatsChip ★总积分 + currentPoints"
```

---

### Task 3: 庆祝「+N 分」(完成 / 番茄完成)

> `CelebrationOverlay` 加可选 `pointsDelta`,非空时显 `+N 分`;`TodoScreen` 完成庆祝传 `pointsDelta: ScoreCalculator.donePoints`。`FocusScreen` 完成态加 `+10 分` 文字。捕获不动画(范围边界)。

**Files:**
- Modify: `lib/features/today/widgets/celebration_overlay.dart`、`lib/features/todo/todo_screen.dart`、`lib/features/todo/focus_screen.dart`
- Test: `test/features/today/celebration_overlay_test.dart`(若有则追加,否则新建)、`test/features/todo/focus_screen_test.dart`

- [ ] **Step 1: 写失败测试(overlay 显 +N 分)**

新建/追加 `test/features/today/celebration_overlay_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/features/today/widgets/celebration_overlay.dart';

void main() {
  testWidgets('传 pointsDelta 时显示 +N 分', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CelebrationOverlay(streak: 1, pointsDelta: 10, onDismiss: () {}),
    ));
    await tester.pump();
    expect(find.textContaining('+10 分'), findsOneWidget);
  });
}
```
（`CelebrationOverlay` 内有 1.9s 后 `onDismiss` 的 `Future.delayed`;此处只 `pump()` 一帧断言文字即可,**勿 `pumpAndSettle`**——confetti/delay 会卡住。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/today/celebration_overlay_test.dart`
Expected: FAIL（`pointsDelta` 参数不存在）

- [ ] **Step 3: CelebrationOverlay 加 pointsDelta**

`lib/features/today/widgets/celebration_overlay.dart`:构造函数加 `this.pointsDelta`、字段 `final int? pointsDelta;`。在「做到了。这就是积累。」那段下方追加:
```dart
              if (pointsDelta != null) ...[
                const SizedBox(height: 10),
                Text('+$pointsDelta 分',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.q1)),
              ],
```

- [ ] **Step 4: TodoScreen 完成庆祝传 delta**

`lib/features/todo/todo_screen.dart`:`_celebrate` 签名加可选 `int? pointsDelta`,透传给 `CelebrationOverlay(streak:..., pointsDelta: pointsDelta, ...)`。`confirmDismiss` 的 `endToStart` 分支里改成:
```dart
          await ctl.complete(t.id);
          final fresh = await ctl.currentStreak();
          if (context.mounted) {
            _celebrate(context, fresh, pointsDelta: ScoreCalculator.donePoints);
          }
```
顶部加 `import '../../domain/score/score_calculator.dart';`。

- [ ] **Step 5: FocusScreen 完成态显 +10 分**

`lib/features/todo/focus_screen.dart` 的 `_done()`,在「番茄完成 +1」下方加一行:
```dart
        const SizedBox(height: 6),
        Text('+${ScoreCalculator.tomatoPoints} 分',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.q1)),
```
顶部加 `import '../../domain/score/score_calculator.dart';`。在既有 `focus_screen_test.dart` 的完成态断言后追加 `expect(find.textContaining('+10 分'), findsOneWidget);`。

- [ ] **Step 6: 全量 + analyze + 提交**

Run: `flutter analyze` → 无 issue;`flutter test` → 全绿。
```bash
git add -A
git commit -m "feat(score): 庆祝弹层 +N 分(完成 +10)+ 番茄完成态 +10 分"
```

---

## 完成判据

- `flutter analyze` 无 issue;`flutter test` 全绿。
- 捕获 → 静默 +2;完成任务 → 庆祝显「+10 分」+ chip `★` 即时跳;番茄完成 → 完成态显「+10 分」+ chip 即时跳。
- 积分**事件派生**(`ScoreCalculator` over `TaskEvents`),无可变计数器、无新 schema 迁移;太难了/降级不计分。
- 未引入连击加成 / 难度加权 / 数字滚动重动画 / 复盘积分聚合 / 桌面跳动。

## 衔接下一计划

MAP 诊断标签(AI 异步:专注时长喂 A、放弃标「需提示」、🍅 估;提示横幅);复盘(数据分析 + 日历切换 + AI,含番茄会话与积分聚合曲线);阶段② 桌面零摩擦捕获 + ntfy 单向同步 + 桌面番茄/积分两端一致。
