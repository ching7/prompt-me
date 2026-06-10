# PromptMe v1 · 阶段①收尾实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。Steps 用 checkbox 跟踪。

**Goal:** 收掉阶段①三个散落缺口 + 出端到端自测清单,让「捕获→收件箱→今日→福格+番茄→复盘」闭环无尾巴可交付。

**收尾项(用户勾选):**
1. **番茄预估入口** — `setTomatoEst` 有方法但无 UI;在 FocusScreen 加「预估 🍅」1–4 选择,卡上显 `N/M`。
2. **AI 整理今日(prioritize)** — `AiClient.prioritize`+`PrioritizeResultView` 现成未接屏;待办屏加「✨AI 整理」按钮→底部弹层显四象限建议+今日先做。门控 `isActive`。
3. **放弃番茄记事件** — FocusScreen「放弃」记一条 `tomatoAbort` 事件(不计完成/不加分);为后续喂 A 诊断留信号。
4. **全链路自测清单** — 文档,逐项验收。

**Architecture:**
- `TaskEventType` 末尾加 `tomatoAbort`(index 4,intEnum 不动旧值);`ScoreCalculator.pointsFor` 补 `tomatoAbort=>0`(穷尽 switch)。
- `TodoController` 加 `setTomatoEst(id,n)`、`abortTomato(id)`(记事件)、`prioritizeToday()`(收集今日待办标题→`ai.prioritize`,isActive 才调)。
- FocusScreen:加 `tomatoEst` 初值入参 + 预估 chip 行(写 setTomatoEst);「放弃」改为先 `abortTomato` 再 pop。
- 待办屏:header 加「✨AI 整理」按钮→`showModalBottomSheet`(loading→`PrioritizeResultView`/关 AI 引导)。

**范围边界(不做):** AI 估🍅(本期手动预估);专注时长喂 A 诊断/放弃→AI 二次分析(只记事件留信号);复盘日历切换/曲线/缓存;阶段② 桌面+ntfy。

**Tech Stack/工程根/前缀坑:** 同前;widget 测试遇持续动画用显式 pump;构建 HomeShell/含 AI 的屏的 widget 测试要 override sharedPrefs。

---

### Task A: 数据/控制器(tomatoAbort + setTomatoEst/abortTomato/prioritizeToday)
**Files:** `lib/domain/enums.dart`、`lib/domain/score/score_calculator.dart`、`lib/state/todo_controller.dart`;Test `test/domain/enums_test.dart`、`test/domain/score/score_calculator_test.dart`、`test/state/todo_controller_*`(或新建)
- [ ] 失败测试:TaskEventType.tomatoAbort 存在且 index==4;ScoreCalculator.pointsFor(tomatoAbort)==0;abortTomato 记一条 tomatoAbort 事件、不加分。
- [ ] 实现枚举 + 计分 + 控制器三方法。
- [ ] 通过 → 提交。

### Task B: FocusScreen 预估入口 + 放弃记事件
**Files:** `lib/features/todo/focus_screen.dart`、`lib/features/todo/todo_screen.dart`(传 tomatoEst);Test `test/features/todo/focus_screen_test.dart`
- [ ] 失败测试:点预估「3」→ 该任务 tomatoEst==3;点「放弃」→ 退出且记 tomatoAbort、tomatoDone 不变。
- [ ] 实现:`_running()` 加预估 chip 行(1–4,高亮当前);放弃 onPressed 先 `abortTomato` 再 pop;`FocusScreen({this.tomatoEst})` 初值。
- [ ] 通过 → 提交。

### Task C: 待办屏 AI 整理今日(prioritize)
**Files:** `lib/state/todo_controller.dart`(prioritizeToday)、`lib/features/todo/todo_screen.dart`;Test `test/features/todo/todo_screen_test.dart`(AI 关→按钮引导,不联网)
- [ ] 失败测试:AI 关时点「AI 整理」→ 弹层显引导(去设置开 AI),不联网。
- [ ] 实现:header 加按钮;`_openPrioritize` showModalBottomSheet:isActive?loading+prioritize+PrioritizeResultView:引导。打日志。
- [ ] 全量 test+analyze → 提交。

### Task D: 全链路自测清单
**Files:** `docs/test/2026-06-10-v1-phase1-final-selftest.md`
- [ ] 写「捕获→收件箱→今日→福格(我做到了/太难了+降级+MAP诊断)→番茄(预估/完成/放弃)→积分→复盘(汇总+AI)→AI 开关」端到端清单 + 预期。
- [ ] 提交。

## 完成判据
- analyze 无 issue;test 全绿。
- 番茄能设预估(卡显 N/M);待办屏能 AI 整理(开 AI)/给引导(关 AI);放弃番茄记 tomatoAbort 不加分;自测清单成文。

## 衔接
阶段② 桌面零摩擦捕获 + ntfy 单向同步;复盘日历/曲线;AI 估🍅 + 专注信号二次分析。
