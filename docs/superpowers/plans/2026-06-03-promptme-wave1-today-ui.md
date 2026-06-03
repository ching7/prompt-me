# PromptMe 第一波 · 计划② 今日时间线与福格闭环 UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把计划①的数据层与纯逻辑接到 UI：做出「今日时间线」主屏，跑通福格闭环——`[我做到了]`(打卡+庆祝) 与 `[太难了]`(选原因→无底线降级→缩成微习惯)，并支持手动新增任务。完成后 App 每天可用（即使还没接订阅/AI/通知）。

**Architecture:** Riverpod 管状态：`databaseProvider` 暴露 Drift；`todayViewProvider`(Stream) 监听今日任务+事件并用 `TodayAggregator` 合成视图；`TodayController` 封装写操作（新增/打卡/太难了）。UI 按职责拆成小 widget，视觉令牌取自 `theme/app_colors.dart` 与高保真原型。降级在本计划用 `Downgrade.localFallback`（确定性本地兜底）；AI 实网降级留计划③。

**Tech Stack:** Flutter · Riverpod 2 · Drift · confetti · flutter_test（widget test）

**前置：** 计划① 已完成且 `flutter test` 全绿。（Flutter 工程位于 `frontend/promptme-app/`，本计划所有 `lib/`/`test/` 路径与 `flutter`/`dart` 命令均在该目录下执行——见 `CLAUDE.md`。）

---

## File Structure（本计划将创建/修改的文件）

```
lib/
  app.dart                                  # 修改：home -> TodayScreen
  state/
    providers.dart                          # databaseProvider / selectedDateProvider / todayViewProvider / streakProvider / mappers
    today_controller.dart                   # addTask / complete / tooHard
  features/today/
    today_screen.dart                       # 主屏装配 + 庆祝/弹层调度
    widgets/
      stats_header.dart                     # 连续天数 + 完成环
      schedule_section.dart                 # 苹果日历事件（计划③才有数据）
      quadrant_section.dart                 # 单个象限分组
      task_card.dart                         # 任务卡 + [做到了]/[太难了]
      too_hard_sheet.dart                   # 选失败原因
      celebration_overlay.dart              # 彩纸 + 连续天数跳动
      add_task_sheet.dart                   # 手动新增任务
test/
  state/today_controller_test.dart
  features/today/today_screen_test.dart
```

---

### Task 1: Riverpod providers 与行映射

**Files:**
- Create: `lib/state/providers.dart`
- Test: `test/state/today_controller_test.dart`（本任务先建文件做映射测试，控制器在 Task 2 加入）

- [ ] **Step 1: 写映射的失败测试**

`test/state/today_controller_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/providers.dart';

void main() {
  test('rowToTodayTask shows micro prompt text after downgrade', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '项目周报',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.manual,
    ));
    var row = await db.taskDao.getById(id);
    expect(rowToTodayTask(row!).title, '项目周报');

    await db.taskDao.applyDowngrade(id, '只看一眼清单', 1);
    row = await db.taskDao.getById(id);
    expect(rowToTodayTask(row!).title, '只看一眼清单'); // 展示降级后的微版本
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/state/today_controller_test.dart`
Expected: 编译失败（`providers.dart` 不存在）。

- [ ] **Step 3: 实现 providers + mappers**

`lib/state/providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/streak_calculator.dart';
import '../domain/fogg/today_aggregator.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// 注：Riverpod 3.x 已移除 StateProvider。此处只读不改，用普通 Provider。
final selectedDateProvider = Provider<DateTime>((_) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

TodayTask rowToTodayTask(Task row) => TodayTask(
      id: row.id,
      title: (row.currentPromptText?.isNotEmpty ?? false)
          ? row.currentPromptText!
          : row.title,
      quadrant: row.quadrant,
      done: row.status == TaskStatus.done,
    );

TodayEvent rowToTodayEvent(CalendarEvent e) => TodayEvent(
      title: e.title,
      start: e.start,
      end: e.end,
      allDay: e.allDay,
      calendarName: e.calendarName,
    );

final todayViewProvider = StreamProvider.autoDispose<TodayView>((ref) async* {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  await for (final taskRows in db.taskDao.watchTasksForDate(date)) {
    final eventRows = await db.calendarDao.eventsForDate(date);
    yield TodayAggregator.build(
      events: eventRows.map(rowToTodayEvent).toList(),
      tasks: taskRows.map(rowToTodayTask).toList(),
    );
  }
});

final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(todayViewProvider); // 任务变化时重算
  final days = await db.taskDao.completionDays();
  return StreakCalculator.currentStreak(days, ref.read(selectedDateProvider));
});
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/state/today_controller_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/state/providers.dart test/state/today_controller_test.dart
git commit -m "feat: riverpod providers + row->VM mappers"
```

---

### Task 2: TodayController（新增/打卡/太难了）

**Files:**
- Create: `lib/state/today_controller.dart`
- Modify: `test/state/today_controller_test.dart`

- [ ] **Step 1: 追加失败测试**

在 `test/state/today_controller_test.dart` 的 `main()` 末尾追加：
```dart
  group('TodayController', () {
    late AppDatabase db;
    late ProviderContainer c;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    });
    tearDown(() {
      c.dispose();
      db.close();
    });

    test('addTask schedules for today with manual source', () async {
      await c.read(todayControllerProvider).addTask(
            title: '项目周报',
            quadrant: Quadrant.importantUrgent,
          );
      final today = DateTime.now();
      final rows = await db.taskDao.tasksForDate(today);
      expect(rows.single.title, '项目周报');
      expect(rows.single.source, TaskSource.manual);
    });

    test('complete marks done and logs a done event', () async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
        title: 'x', quadrant: Quadrant.importantUrgent, source: TaskSource.manual));
      await c.read(todayControllerProvider).complete(id);
      expect((await db.taskDao.getById(id))!.status, TaskStatus.done);
      expect((await db.taskEventDao.forTask(id)).single.type, TaskEventType.done);
    });

    test('tooHard shrinks, bumps level, logs reason', () async {
      final id = await db.taskDao.insertTask(TasksCompanion.insert(
        title: '完成项目周报', quadrant: Quadrant.importantUrgent, source: TaskSource.manual));
      final micro = await c.read(todayControllerProvider).tooHard(id, FailureReason.tired);
      expect(micro, contains('完成项目周报'));
      final row = await db.taskDao.getById(id);
      expect(row!.downgradeLevel, 1);
      expect(row.currentPromptText, micro);
      final ev = (await db.taskEventDao.forTask(id)).single;
      expect(ev.type, TaskEventType.tooHard);
      expect(ev.reason, FailureReason.tired);
    });
  });
```
并在文件顶部补 import：
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/state/today_controller.dart';
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/state/today_controller_test.dart`
Expected: 编译失败（`today_controller.dart` / `todayControllerProvider` 不存在）。

- [ ] **Step 3: 实现控制器**

`lib/state/today_controller.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/downgrade.dart';
import 'providers.dart';

class TodayController {
  TodayController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addTask({
    required String title,
    required Quadrant quadrant,
  }) async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    await _db.taskDao.insertTask(TasksCompanion.insert(
      title: title,
      quadrant: quadrant,
      source: TaskSource.manual,
      scheduledDate: Value(today),
      firstScheduledDate: Value(today),
    ));
  }

  Future<void> complete(int id) async {
    final now = DateTime.now();
    await _db.taskDao.markDone(id, now);
    await _db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.done,
      createdAt: now,
    ));
  }

  /// 无底线降级：每次在原任务基础上把层级 +1，用本地兜底文案生成微习惯。
  /// 返回新的微习惯文案。AI 实网降级在计划③替换实现。
  Future<String> tooHard(int id, FailureReason reason) async {
    final task = await _db.taskDao.getById(id);
    final level = (task?.downgradeLevel ?? 0) + 1;
    final micro = Downgrade.localFallback(task?.title ?? '', level);
    await _db.taskDao.applyDowngrade(id, micro, level);
    await _db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.tooHard,
      createdAt: DateTime.now(),
      reason: Value(reason),
      microVersionText: Value(micro),
    ));
    return micro;
  }
}

final todayControllerProvider =
    Provider<TodayController>((ref) => TodayController(ref));
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/state/today_controller_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/state/today_controller.dart test/state/today_controller_test.dart
git commit -m "feat: TodayController (addTask/complete/tooHard) + tests"
```

---

### Task 3: 任务卡 TaskCard

**Files:**
- Create: `lib/features/today/widgets/task_card.dart`

- [ ] **Step 1: 实现 TaskCard**

`lib/features/today/widgets/task_card.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.quadrant,
    required this.isMicro,
    required this.onDone,
    required this.onTooHard,
  });

  final String title;
  final Quadrant quadrant;
  final bool isMicro; // 已降级则换一种视觉
  final VoidCallback onDone;
  final VoidCallback onTooHard;

  Color get _accent => switch (quadrant) {
        Quadrant.importantUrgent => AppColors.q1,
        Quadrant.importantNotUrgent => AppColors.q2,
        Quadrant.notImportantUrgent => AppColors.q3,
        Quadrant.notImportantNotUrgent => AppColors.q4,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMicro ? const Color(0xFFEAF3E9) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMicro ? const Color(0x554F9D5E) : AppColors.ink20,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: isMicro ? AppColors.leaf : _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMicro)
                        _Badge(
                          text: '⚡ 2 分钟微习惯',
                          color: AppColors.leaf,
                          bg: const Color(0x224F9D5E),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionBtn(
                              label: '我做到了',
                              filled: true,
                              icon: Icons.check,
                              onTap: onDone,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _ActionBtn(
                              label: isMicro ? '还是难' : '太难了',
                              filled: false,
                              icon: Icons.south,
                              onTap: onTooHard,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.bg});
  final String text;
  final Color color;
  final Color bg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ink20, width: 1.5),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: filled ? AppColors.leaf : AppColors.q3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: filled ? AppColors.paper : AppColors.ink60)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 静态检查 + Commit**

Run: `flutter analyze lib/features/today/widgets/task_card.dart`
Expected: No issues.
```bash
git add lib/features/today/widgets/task_card.dart
git commit -m "feat: TaskCard widget with done/too-hard actions"
```

---

### Task 4: 统计头、日程段、象限段

**Files:**
- Create: `lib/features/today/widgets/stats_header.dart`
- Create: `lib/features/today/widgets/schedule_section.dart`
- Create: `lib/features/today/widgets/quadrant_section.dart`

- [ ] **Step 1: StatsHeader（连续天数 + 完成环）**

`lib/features/today/widgets/stats_header.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.streak,
    required this.done,
    required this.total,
  });
  final int streak;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0.0 : done / total;
    return Row(
      children: [
        Expanded(
          child: _box(
            label: '连续天数',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('$streak',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w700, height: 1)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('天',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.ink40)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _box(
            label: '今日完成',
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: rate,
                          strokeWidth: 7,
                          backgroundColor: AppColors.ink20,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.leaf),
                        ),
                      ),
                      Text('${(rate * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('$done/$total',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _box({required String label, required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink60)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}
```

- [ ] **Step 2: ScheduleSection（日历事件，计划③才有数据）**

`lib/features/today/widgets/schedule_section.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/fogg/today_aggregator.dart';
import '../../../theme/app_colors.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.events});
  final List<TodayEvent> events;

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('日程 · 苹果日历'),
        ...events.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(e.allDay ? '全天' : _hhmm(e.start),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink60)),
                  ),
                  Container(
                    width: 3,
                    height: 28,
                    color: AppColors.q3,
                    margin: const EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                      child: Text(e.title,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
      );
}
```

- [ ] **Step 3: QuadrantSection（单象限分组）**

`lib/features/today/widgets/quadrant_section.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../domain/fogg/today_aggregator.dart';
import '../../../theme/app_colors.dart';
import 'task_card.dart';

class QuadrantSection extends StatelessWidget {
  const QuadrantSection({
    super.key,
    required this.quadrant,
    required this.tasks,
    required this.microIds,
    required this.onDone,
    required this.onTooHard,
  });

  final Quadrant quadrant;
  final List<TodayTask> tasks;
  final Set<int> microIds; // 已降级的任务 id
  final void Function(int id) onDone;
  final void Function(int id) onTooHard;

  Color get _dot => switch (quadrant) {
        Quadrant.importantUrgent => AppColors.q1,
        Quadrant.importantNotUrgent => AppColors.q2,
        Quadrant.notImportantUrgent => AppColors.q3,
        Quadrant.notImportantNotUrgent => AppColors.q4,
      };

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _dot, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(quadrant.label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        ...tasks.map((t) => TaskCard(
              title: t.title,
              quadrant: t.quadrant,
              isMicro: microIds.contains(t.id),
              onDone: () => onDone(t.id),
              onTooHard: () => onTooHard(t.id),
            )),
      ],
    );
  }
}
```

- [ ] **Step 4: 静态检查 + Commit**

Run: `flutter analyze lib/features/today/widgets/`
Expected: No issues.
```bash
git add lib/features/today/widgets/stats_header.dart lib/features/today/widgets/schedule_section.dart lib/features/today/widgets/quadrant_section.dart
git commit -m "feat: stats header, schedule + quadrant sections"
```

---

### Task 5: 太难了弹层、庆祝层、新增任务弹层

**Files:**
- Create: `lib/features/today/widgets/too_hard_sheet.dart`
- Create: `lib/features/today/widgets/celebration_overlay.dart`
- Create: `lib/features/today/widgets/add_task_sheet.dart`

- [ ] **Step 1: TooHardSheet（返回所选原因）**

`lib/features/today/widgets/too_hard_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

/// 以 modal bottom sheet 形式展示，用户选原因后返回该 [FailureReason]。
Future<FailureReason?> showTooHardSheet(BuildContext context, String taskTitle) {
  return showModalBottomSheet<FailureReason>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _TooHardSheet(taskTitle: taskTitle),
  );
}

class _TooHardSheet extends StatelessWidget {
  const _TooHardSheet({required this.taskTitle});
  final String taskTitle;

  static const _reasons = [
    (FailureReason.forgot, '🌫️', 'P · 提示没接住'),
    (FailureReason.tired, '🪫', 'A · 能力/精力不够'),
    (FailureReason.noMotivation, '🫥', 'M · 动机不足'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.ink20,
                    borderRadius: BorderRadius.circular(5))),
          ),
          const SizedBox(height: 18),
          const Text('这件事太难了？没关系，我把它变小。',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 8),
          Text('选一个原因——我会据此把「$taskTitle」降到 2 分钟。',
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink60)),
          const SizedBox(height: 18),
          ..._reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, r.$1),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.ink20, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(r.$2, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1.label,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                              Text(r.$3,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink40)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          const Center(
            child: Text('降低门槛不是放弃。动机推不动、累也消不掉，但「变小」永远做得到。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.ink40)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: CelebrationOverlay（彩纸 + 连续天数）**

`lib/features/today/widgets/celebration_overlay.dart`:
```dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.streak,
    required this.onDismiss,
  });
  final int streak;
  final VoidCallback onDismiss;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _confetti.play();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper.withValues(alpha: 0.98),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 22,
              maxBlastForce: 18,
              colors: const [
                AppColors.q1,
                AppColors.q2,
                AppColors.q3,
                AppColors.leaf,
                AppColors.pop,
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                    color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.leaf, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('连续天数 +1',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.ink40)),
              const SizedBox(height: 6),
              Text('🔥 ${widget.streak}',
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w700, height: 1)),
              const SizedBox(height: 18),
              const Text('做到了。这就是积累。',
                  style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
```

> 注：`Color.withValues` 是较新 Flutter API；若当前 SDK 不支持，改用 `AppColors.paper.withOpacity(0.98)`。

- [ ] **Step 3: AddTaskSheet（手动新增）**

`lib/features/today/widgets/add_task_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

class AddTaskResult {
  final String title;
  final Quadrant quadrant;
  AddTaskResult(this.title, this.quadrant);
}

Future<AddTaskResult?> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet<AddTaskResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _ctrl = TextEditingController();
  Quadrant _q = Quadrant.importantUrgent;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          const Text('加一件今天要做的事',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '例如：完成项目周报',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.ink20)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: Quadrant.values
                .map((q) => ChoiceChip(
                      label: Text(q.label),
                      selected: _q == q,
                      onSelected: (_) => setState(() => _q = q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: () {
                final text = _ctrl.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, AddTaskResult(text, _q));
              },
              child: const Text('加入今日'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 静态检查 + Commit**

Run: `flutter analyze lib/features/today/widgets/`
Expected: No issues（若 `withValues` 报错，按注释改 `withOpacity` 再跑）。
```bash
git add lib/features/today/widgets/too_hard_sheet.dart lib/features/today/widgets/celebration_overlay.dart lib/features/today/widgets/add_task_sheet.dart
git commit -m "feat: too-hard sheet, celebration overlay, add-task sheet"
```

---

### Task 6: 今日主屏装配

**Files:**
- Create: `lib/features/today/today_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: 实现 TodayScreen**

`lib/features/today/today_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/enums.dart';
import '../../domain/fogg/today_aggregator.dart';
import '../../state/providers.dart';
import '../../state/today_controller.dart';
import '../../theme/app_colors.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/quadrant_section.dart';
import 'widgets/schedule_section.dart';
import 'widgets/stats_header.dart';
import 'widgets/too_hard_sheet.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _celebrating = false;
  int _celebrateStreak = 0;

  Future<void> _onDone(int id) async {
    await ref.read(todayControllerProvider).complete(id);
    final streak = await ref.read(streakProvider.future);
    if (!mounted) return;
    setState(() {
      _celebrating = true;
      _celebrateStreak = streak;
    });
  }

  Future<void> _onTooHard(int id, String title) async {
    final reason = await showTooHardSheet(context, title);
    if (reason == null) return;
    final micro = await ref.read(todayControllerProvider).tooHard(id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已为你变小：$micro')),
    );
  }

  Future<void> _onAdd() async {
    final result = await showAddTaskSheet(context);
    if (result == null) return;
    await ref
        .read(todayControllerProvider)
        .addTask(title: result.title, quadrant: result.quadrant);
  }

  @override
  Widget build(BuildContext context) {
    final viewAsync = ref.watch(todayViewProvider);
    final streak = ref.watch(streakProvider).value ?? 0; // Riverpod 3.x 用 .value
    final date = ref.watch(selectedDateProvider);
    final microIds = _collectMicroIds(viewAsync.valueOrNull);

    return Stack(
      children: [
        Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.ink,
            onPressed: _onAdd,
            child: const Icon(Icons.add, color: AppColors.paper),
          ),
          body: SafeArea(
            child: viewAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('出错了：$e')),
              data: (view) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _header(context, date),
                  const SizedBox(height: 18),
                  StatsHeader(
                      streak: streak,
                      done: view.doneCount,
                      total: view.totalCount),
                  const SizedBox(height: 22),
                  ScheduleSection(events: view.events),
                  for (final q in _orderedQuadrants())
                    QuadrantSection(
                      quadrant: q,
                      tasks: view.byQuadrant[q] ?? const [],
                      microIds: microIds,
                      onDone: _onDone,
                      onTooHard: (id) => _onTooHard(id, _titleOf(view, id)),
                    ),
                  if (view.completed.isNotEmpty) _completed(view),
                  if (view.totalCount == 0) _emptyHint(),
                ],
              ),
            ),
          ),
        ),
        if (_celebrating)
          CelebrationOverlay(
            streak: _celebrateStreak,
            onDismiss: () => setState(() => _celebrating = false),
          ),
      ],
    );
  }

  List<Quadrant> _orderedQuadrants() =>
      [...Quadrant.values]..sort((a, b) => a.priority - b.priority);

  Set<int> _collectMicroIds(TodayView? view) => {}; // 由 currentPromptText 决定的视觉在 mapper 已处理 title；此处保留扩展位
  // 注：是否“微习惯样式”可由 downgradeLevel 判断；当前 TodayTask 未带该字段，
  // 故 isMicro 暂以空集合（不特殊着色）。计划③接入 AI 时再把 downgradeLevel 透传到 VM。

  String _titleOf(TodayView view, int id) {
    for (final list in view.byQuadrant.values) {
      for (final t in list) {
        if (t.id == id) return t.title;
      }
    }
    return '';
  }

  Widget _header(BuildContext context, DateTime date) {
    final df = DateFormat('M月d日 · EEEE', 'zh');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(df.format(date),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.ink40)),
            const SizedBox(height: 3),
            Text('今天',
                style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const Text('PromptMe',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: AppColors.ink60)),
      ],
    );
  }

  Widget _completed(TodayView view) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Divider(color: AppColors.ink20),
          ...view.completed.map((t) => Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.leaf, shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(t.title,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
              )),
        ],
      );

  Widget _emptyHint() => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Text('今天还没有任务。\n点右下角 + 加一件，或在设置里导入飞书。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink40, height: 1.6)),
        ),
      );
}
```

> 说明：`isMicro` 的特殊着色依赖把 `downgradeLevel` 透到 VM。为不在本计划改动计划①的 `TodayTask`，此处 `microIds` 暂为空集合（功能不受影响：降级后卡片标题已变成微习惯文案）。计划③接入 AI 时，把 `downgradeLevel` 加进 `TodayTask` 并填充 `microIds`，即可恢复绿色微习惯样式。

- [ ] **Step 2: 接到 app.dart**

修改 `lib/app.dart`，把 `home:` 替换为今日屏（其余保留）：
```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'features/today/today_screen.dart';

class PromptMeApp extends StatelessWidget {
  const PromptMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('zh');
    return MaterialApp(
      title: 'PromptMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const TodayScreen(),
    );
  }
}
```

- [ ] **Step 3: 静态检查 + 启动走查**

Run: `flutter analyze`
Expected: No issues.
Run: `flutter run -d android`
手动验证：右下 + 新增任务 → 出现在对应象限 → 点「我做到了」出现彩纸 + 连续天数 → 点「太难了」选「太累」→ snackbar 显示微习惯、卡片标题变成微版本。停止运行。

- [ ] **Step 4: Commit**

```bash
git add lib/features/today/today_screen.dart lib/app.dart
git commit -m "feat: TodayScreen wiring fogg loop (done/celebration/too-hard/add)"
```

---

### Task 7: Widget 测试（闭环行为）

**Files:**
- Create: `test/features/today/today_screen_test.dart`

- [ ] **Step 1: 写测试**

`test/features/today/today_screen_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/today/today_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('zh');
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: TodayScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<int> seedTask() => db.taskDao.insertTask(TasksCompanion.insert(
        title: '完成项目周报',
        quadrant: Quadrant.importantUrgent,
        source: TaskSource.manual,
        scheduledDate: Value(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)),
      ));

  testWidgets('tapping 我做到了 marks task done', (tester) async {
    final id = await seedTask();
    await pump(tester);
    expect(find.text('完成项目周报'), findsOneWidget);

    await tester.tap(find.text('我做到了'));
    await tester.pump(); // 触发 complete
    await tester.pump(const Duration(milliseconds: 100));

    expect((await db.taskDao.getById(id))!.status, TaskStatus.done);
  });

  testWidgets('太难了 → 选原因 → 任务降级', (tester) async {
    final id = await seedTask();
    await pump(tester);

    await tester.tap(find.text('太难了'));
    await tester.pumpAndSettle(); // 弹层

    await tester.tap(find.text('太累'));
    await tester.pumpAndSettle();

    final row = await db.taskDao.getById(id);
    expect(row!.downgradeLevel, 1);
    expect(row.currentPromptText, isNotNull);
    final ev = (await db.taskEventDao.forTask(id)).single;
    expect(ev.reason, FailureReason.tired);
  });
}
```

- [ ] **Step 2: 运行**

Run: `flutter test test/features/today/today_screen_test.dart`
Expected: All tests passed.（若庆祝层 1.9s 延时导致 pumpAndSettle 超时，第一个测试用 `tester.pump(Duration)` 已避免；如仍超时，在断言后 `await tester.pump(const Duration(seconds: 2));` 让 overlay 自行 dismiss。）

- [ ] **Step 3: 全量测试 + Commit**

Run: `flutter test`
Expected: 全绿（计划① + 计划②）。
```bash
git add test/features/today/today_screen_test.dart
git commit -m "test: today screen fogg-loop widget tests"
```

---

## Self-Review

**Spec 覆盖：** 今日时间线（顶部连续天数/完成环 + 日程 + 四象限）→ Task 4/6；`[做到了]` 打卡+庆祝+TaskEvent → Task 2/5/6；`[太难了]` 选原因→无底线降级→TaskEvent + 卡片变微习惯 → Task 2/5/6；手动新增任务 → Task 5/6。日程段在无数据时折叠（计划③接订阅后有数据）。AI 实网降级与「刷到锁屏」留计划③（本计划用本地兜底 + snackbar）。✅

**Placeholder scan：** 无 TBD/TODO；每步含完整代码与命令。两处“扩展位”（`microIds` 空集合、`withValues` 兼容）均有明确说明与可执行的退路，非占位。✅

**Type consistency：** `todayControllerProvider`/`TodayController.{addTask,complete,tooHard}`、`databaseProvider`/`selectedDateProvider`/`todayViewProvider`/`streakProvider`、`rowToTodayTask/rowToTodayEvent`、`showTooHardSheet`/`showAddTaskSheet`/`AddTaskResult`、`TaskCard`/`StatsHeader`/`ScheduleSection`/`QuadrantSection`/`CelebrationOverlay` 跨任务签名一致。引用计划① 的 `TodayView/TodayTask/TodayEvent/Quadrant/FailureReason/Downgrade` 与 DAO 方法一致。✅
