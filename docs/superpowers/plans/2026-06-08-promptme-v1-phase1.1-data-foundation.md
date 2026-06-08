# PromptMe v1 · 阶段 1.1 数据层地基 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给现有 Flutter 工程的数据层加上 v1 转向所需的地基——领域标签、捕获来源、收件箱/加入今日的 DAO 查询——纯数据层、TDD,不动任何 UI。

**Architecture:** 在已有的 Drift(SQLite)+ Riverpod 工程上**增量加列 + 加 DAO 方法**,不删旧表/旧列(沿用 spec「保留 quadrant 列不用」的低运维原则)。`TaskSource` 追加 `capture`(枚举末尾,保持 intEnum 索引稳定);`Tasks` 加 `domain` 文本列(领域标签,可空=未分类,支持自定义);schema 升到 v2 + `addColumn` 迁移。`TaskDao` 加捕获插入、收件箱查询、加入今日、设标签四个方法。降级关联无需改库——`Tasks.parentTaskId` 与 `downgradeLevel` 列已存在。

**Tech Stack:** Flutter 3.12 / Dart;drift 2.33 + drift_dev(build_runner 代码生成);flutter_test。

**工程根:** 所有路径与命令在 `frontend/promptme-app/` 下执行(不是仓库根)。`spec` 见 `docs/superpowers/specs/2026-06-05-promptme-v1-capture-gtd-pivot.md` §6 数据模型。

---

### Task 1: `TaskSource.capture` 枚举值

**Files:**
- Modify: `lib/domain/enums.dart:32`
- Test: `test/domain/enums_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/domain/enums_test.dart` 末尾(`main()` 内)追加:

```dart
test('TaskSource.capture 追加在末尾、index=2', () {
  expect(TaskSource.values.length, 3);
  expect(TaskSource.capture.index, 2);
  // 既有值索引不变（intEnum 存的是 index，不能挪动）
  expect(TaskSource.manual.index, 0);
  expect(TaskSource.feishu.index, 1);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/enums_test.dart`
Expected: FAIL —「The getter 'capture' isn't defined for the type 'TaskSource'」

- [ ] **Step 3: 加枚举值**

把 `lib/domain/enums.dart:32` 的

```dart
enum TaskSource { manual, feishu }
```

改成(只在末尾追加,不动顺序):

```dart
enum TaskSource { manual, feishu, capture }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/enums_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/domain/enums.dart test/domain/enums_test.dart
git commit -m "feat(data): TaskSource.capture 枚举值"
```

---

### Task 2: 领域标签默认集合 `domains.dart`

> 领域标签存为文本(标签字符串),`null`=未分类,任意非默认字符串=自定义。默认集合与判定放纯 dart 文件(无 flutter 依赖,可纯单测);颜色映射留给后续 UI 计划在 `theme/` 做。

**Files:**
- Create: `lib/domain/domains.dart`
- Test: `test/domain/domains_test.dart`

- [ ] **Step 1: 写失败测试**

新建 `test/domain/domains_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/domains.dart';

void main() {
  test('四个默认领域、顺序固定', () {
    expect(kDefaultDomains, ['工作', '自媒体', '学习', '家庭']);
  });

  test('isCustomDomain：非空且不在默认集合里才算自定义', () {
    expect(isCustomDomain('工作'), false);
    expect(isCustomDomain('副业'), true);
    expect(isCustomDomain(null), false);
    expect(isCustomDomain(''), false);
    expect(isCustomDomain('  '), false);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/domains_test.dart`
Expected: FAIL —「Target of URI doesn't exist: 'package:promptme/domain/domains.dart'」

- [ ] **Step 3: 写实现**

新建 `lib/domain/domains.dart`:

```dart
/// 领域标签：默认四个 + 自定义（任意其它字符串）。`null`/空 = 未分类。
const List<String> kDefaultDomains = ['工作', '自媒体', '学习', '家庭'];

bool isCustomDomain(String? label) {
  if (label == null) return false;
  final s = label.trim();
  return s.isNotEmpty && !kDefaultDomains.contains(s);
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/domains_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/domain/domains.dart test/domain/domains_test.dart
git commit -m "feat(data): 领域标签默认集合 + 自定义判定"
```

---

### Task 3: `Tasks.domain` 列 + schema v2 迁移

> 加一列、升 schemaVersion、加 `onUpgrade` 迁移。旧表(Subscriptions/CalendarEvents/quadrant 列)一律保留不动——清理在 Plan 1.2 做、且只删 Dart 代码不动表,避免 drop 迁移。

**Files:**
- Modify: `lib/data/database.dart:35`(Tasks 表内追加列)、`:72`(schemaVersion)、新增 `migration` getter
- Regenerate: `lib/data/database.g.dart`(build_runner 生成,勿手改)
- Test: `test/data/task_dao_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/data/task_dao_test.dart` 的 `main()` 内追加:

```dart
test('domain 列可写可读、默认 null', () async {
  final id = await db.taskDao.insertTask(TasksCompanion.insert(
    title: '研究 MCP 协议',
    quadrant: Quadrant.importantUrgent,
    source: TaskSource.capture,
    domain: Value('学习'),
  ));
  final t = await db.taskDao.getById(id);
  expect(t!.domain, '学习');

  final id2 = await db.taskDao.insertTask(TasksCompanion.insert(
    title: '没打标签的',
    quadrant: Quadrant.importantUrgent,
    source: TaskSource.capture,
  ));
  final t2 = await db.taskDao.getById(id2);
  expect(t2!.domain, isNull);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/task_dao_test.dart`
Expected: FAIL —「The named parameter 'domain' isn't defined」(`TasksCompanion.insert` 还没有 domain)

- [ ] **Step 3: 加列 + 迁移**

在 `lib/data/database.dart` 的 `Tasks` 表里,`downgradeLevel` 那行(`:34`)后面追加一列:

```dart
  IntColumn get downgradeLevel => integer().withDefault(const Constant(0))();
  TextColumn get domain => text().nullable()();
```

把 `schemaVersion`(`:72`)从 `1` 改成 `2`:

```dart
  @override
  int get schemaVersion => 2;
```

紧接 `schemaVersion` getter 之后,新增迁移策略:

```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.domain);
          }
        },
      );
```

- [ ] **Step 4: 重新生成 drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成成功,`lib/data/database.g.dart` 里 `Task`/`TasksCompanion` 多出 `domain` 字段。

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/data/task_dao_test.dart`
Expected: PASS(原有两条用例 + 新增一条全过)

- [ ] **Step 6: 提交**

```bash
git add lib/data/database.dart lib/data/database.g.dart test/data/task_dao_test.dart
git commit -m "feat(data): Tasks.domain 列 + schema v2 迁移"
```

---

### Task 4: `TaskDao.insertCapture` + `watchInbox`

> 捕获 = 一条 `source=capture` 的 Task;`scheduledDate=null` 进收件箱,给今天即进待办。`quadrant` 是非空列、UI 不用,插入时给占位默认值。收件箱查询 = 无排期 + 待办,新→旧。

**Files:**
- Modify: `lib/data/daos/task_dao.dart`
- Test: `test/data/task_dao_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/data/task_dao_test.dart` 的 `main()` 内追加:

```dart
test('insertCapture 进收件箱、watchInbox 只出无排期的待办（新→旧）', () async {
  await db.taskDao.insertCapture(title: '第一条', domain: '学习');
  await db.taskDao.insertCapture(title: '第二条');
  // 一条直接给今天 → 不应出现在收件箱
  await db.taskDao
      .insertCapture(title: '今天就做', scheduledDate: d(8));

  final inbox = await db.taskDao.watchInbox().first;
  expect(inbox.map((t) => t.title), ['第二条', '第一条']); // id 倒序
  expect(inbox.first.source, TaskSource.capture);
  expect(inbox.last.domain, '学习');
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/task_dao_test.dart`
Expected: FAIL —「The method 'insertCapture' isn't defined for the type 'TaskDao'」

- [ ] **Step 3: 写实现**

在 `lib/data/daos/task_dao.dart` 的 `TaskDao` 类内(`insertTask` 之后)追加:

```dart
  /// 捕获一条：source=capture，scheduledDate=null 进收件箱、=今天进待办。
  Future<int> insertCapture({
    required String title,
    String? domain,
    DateTime? scheduledDate,
  }) =>
      into(tasks).insert(TasksCompanion.insert(
        title: title,
        quadrant: Quadrant.importantUrgent, // 占位，UI 不用
        source: TaskSource.capture,
        domain: Value(domain),
        scheduledDate: Value(scheduledDate),
      ));

  /// 收件箱 = 无排期且待办，新→旧。
  Stream<List<Task>> watchInbox() => (select(tasks)
        ..where((t) =>
            t.scheduledDate.isNull() &
            t.status.equalsValue(TaskStatus.pending))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .watch();
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/task_dao_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/data/daos/task_dao.dart test/data/task_dao_test.dart
git commit -m "feat(data): TaskDao.insertCapture + watchInbox"
```

---

### Task 5: `TaskDao.addToToday` + `setDomain`

> 加入今日 = 置 `scheduledDate=今天`(只取日期部分),并在首次排期时记 `firstScheduledDate`(逾期/连续天数后续要用)。setDomain = 整理时补/改领域标签。

**Files:**
- Modify: `lib/data/daos/task_dao.dart`
- Test: `test/data/task_dao_test.dart`

- [ ] **Step 1: 写失败测试**

在 `test/data/task_dao_test.dart` 的 `main()` 内追加:

```dart
test('addToToday 置今天日期 + 记 firstScheduledDate；setDomain 改标签', () async {
  final id = await db.taskDao.insertCapture(title: '收件箱里的');
  await db.taskDao.addToToday(id, d(8, 14)); // 带了时分，应只留日期
  var t = await db.taskDao.getById(id);
  expect(t!.scheduledDate, DateTime(2026, 6, 8));
  expect(t.firstScheduledDate, DateTime(2026, 6, 8));

  // 不再出现在收件箱
  final inbox = await db.taskDao.watchInbox().first;
  expect(inbox.where((x) => x.id == id), isEmpty);

  await db.taskDao.setDomain(id, '工作');
  t = await db.taskDao.getById(id);
  expect(t!.domain, '工作');

  await db.taskDao.setDomain(id, null);
  t = await db.taskDao.getById(id);
  expect(t!.domain, isNull);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/task_dao_test.dart`
Expected: FAIL —「The method 'addToToday' isn't defined for the type 'TaskDao'」

- [ ] **Step 3: 写实现**

在 `lib/data/daos/task_dao.dart` 的 `TaskDao` 类内追加:

```dart
  /// 加入今日：scheduledDate=今天（仅日期），首次排期记 firstScheduledDate。
  Future<void> addToToday(int id, DateTime today) async {
    final dateOnly = DateTime(today.year, today.month, today.day);
    final existing = await getById(id);
    await (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      scheduledDate: Value(dateOnly),
      firstScheduledDate: Value(existing?.firstScheduledDate ?? dateOnly),
    ));
  }

  /// 设/清领域标签。
  Future<void> setDomain(int id, String? domain) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(domain: Value(domain)));
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/task_dao_test.dart`
Expected: PASS

- [ ] **Step 5: 全量回归 + 提交**

Run: `flutter test`
Expected: 全绿(注意:本计划不碰日历/飞书,旧测试应仍全过)。

```bash
git add lib/data/daos/task_dao.dart test/data/task_dao_test.dart
git commit -m "feat(data): TaskDao.addToToday + setDomain"
```

---

## 完成判据

- `flutter analyze` 无错;`flutter test` 全绿。
- `Tasks` 有 `domain` 列、schema v2 迁移就位;`TaskSource.capture` 可用。
- `TaskDao` 具备:`insertCapture` / `watchInbox` / `addToToday` / `setDomain`(+ 既有 `applyDowngrade`/`completionDays` 等不变)。
- 未触碰任何 UI、未删任何旧表/旧文件(清理留给 Plan 1.2)。

## 衔接下一计划

Plan 1.2(清理遗留 + 3-Tab 骨架):删 日历/飞书/四象限 的 feature/service/parser/dao 代码与测试、`app.dart` 改 3-Tab Scaffold + 底部导航(收件箱/待办/复盘 空壳),`providers` 暴露 `watchInbox` 等。届时再依赖本计划落下的 DAO 方法。
