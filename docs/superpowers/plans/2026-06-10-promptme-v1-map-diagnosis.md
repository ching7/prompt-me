# PromptMe v1 · MAP 诊断标签(确定性版)实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。Steps 用 checkbox 跟踪。

**Goal:** 把一个任务历次「太难了」的失败原因(P/A/M)累积成**任务级诊断**——「这个任务总卡在『能力』」,显示在待办卡上。让用户一眼看到反复栽在哪个福格要素,与已 MAP 化的降级策略形成闭环。

**关键洞察:** 每次 `tooHard` 的 `reason` **已记在 `TaskEvents`**(`reason` 列)。诊断 = 对某任务的 tooHard 事件按 P/A/M 计数取主因 → **纯派生**,和积分/连续天数同一套响应式模式,**零新 schema、零迁移**。

**Architecture:**
- 新建纯域 `lib/domain/fogg/map_diagnosis.dart`:`MapDiagnosis.from(Iterable<FailureReason>)` → 计数 + 主因(`dominant`)。规则:总数 ≥2 且有**唯一最高**才给主因;平票/不足 → 无标签(只暴露清晰模式)。`label` = 「总卡在「${name}·${letter}」」。
- `TaskEventDao` 加 `watchForTask(taskId)` 流。
- `providers.dart` 加 `taskDiagnosisProvider = StreamProvider.family<MapDiagnosis,int>`,watch 某任务 tooHard 事件 → `MapDiagnosis.from`。
- `TodoCard` 加可选 `diagnosisLabel`;非空时在降级徽标区下方显一行「🩺 总卡在…」。
- `todo_screen` build 里对每个 pending 任务 `ref.watch(taskDiagnosisProvider(t.id)).value?.label` 传入卡片(done 任务不显)。

**范围边界(不做):** AI 诊断洞察/建议(本期纯确定性计数;AI 版后续,会查 isActive 开关);复盘屏的 MAP 聚合/曲线(复盘计划再做);把诊断喂回降级 prompt(已有 reason 直接对症,无需);专注时长喂 A、放弃标「需提示」等其它 MAP 信号(后续)。

**Tech Stack:** Flutter 3.44 / Dart 3.12;riverpod 3.x;drift 2.33;flutter_test。
**工程根:** `frontend/promptme-app/`。分支 `feat/v1-map-diagnosis`。前置 1.1–1.7 + AI 开关 + MAP 降级 已在 master。
**⚠️ 跑测试带代理前缀;别 flutter clean。**

---

### Task 1: `MapDiagnosis` 纯域 + 测试
**Files:** Create `lib/domain/fogg/map_diagnosis.dart`、`test/domain/fogg/map_diagnosis_test.dart`
- [ ] 失败测试:`from([tired,tired,forgot])`.dominant == tired;`from([tired,forgot])`(平票).dominant == null;`from([tired])`(不足2).dominant == null;`from([])`.dominant==null;label 含「能力」。
- [ ] 实现 `MapDiagnosis`(counts/total/dominant/label)。
- [ ] 测试通过 → 提交。

### Task 2: `watchForTask` 流 + `taskDiagnosisProvider`
**Files:** Modify `lib/data/daos/task_event_dao.dart`、`lib/state/providers.dart`;Test `test/data/task_event_dao_test.dart`(若有)
- [ ] `TaskEventDao.watchForTask(taskId)` = `(select(taskEvents)..where(taskId==)).watch()`。
- [ ] `taskDiagnosisProvider` family:watch → filter tooHard&reason!=null → `MapDiagnosis.from`。
- [ ] analyze + 相关测试通过 → 提交。

### Task 3: 待办卡显诊断标签
**Files:** Modify `lib/features/todo/todo_card.dart`、`lib/features/todo/todo_screen.dart`;Test `test/features/todo/todo_card_test.dart`
- [ ] TodoCard 加 `this.diagnosisLabel`;非空时在降级徽标下方显「🩺 $label」(leaf/ink 弱色)。补已有用例必填项不受影响(可选参数,无需改)。
- [ ] todo_screen build 对 pending 任务传 `ref.watch(taskDiagnosisProvider(t.id)).value?.label`;done 传 null。
- [ ] card 测试:传 diagnosisLabel → 显文字;不传 → 无。
- [ ] 全量 test + analyze → 提交。

## 完成判据
- analyze 无 issue;test 全绿。
- 某任务连续两次同一原因「太难了」→ 卡上出现「🩺 总卡在『…』」;平票/单次不显。
- 纯派生,无新 schema;done 任务不显诊断。

## 衔接
AI 诊断洞察(查 isActive,给「针对『提示』塌的具体建议」);复盘屏 MAP 聚合曲线;专注/放弃等更多 MAP 信号。
