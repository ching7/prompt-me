# PromptMe v1 · 复盘屏 + AI 洞察实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。Steps 用 checkbox 跟踪。

**Goal:** 把占位的「复盘」Tab 变成真屏:**今日为主 + 累计背景**的数据汇总(完成/番茄/太难了 · 🔥连续/★总积分/MAP 主因),外加一个**按钮手动触发**的 AI 复盘洞察(复用现成 `AiClient.review`,门控 `isActive`)。

**决策(已确认):** 时间范围=今日为主、累计 MAP 作背景;AI 洞察=按钮手动生成(省 token、用户控节奏;关 AI 时按钮置灰+引导去设置)。

**复用:** `AiClient.review(descriptions)`→`List<ReviewItem>`(已 MAP 化、判 M/A/P+给建议,已测)、`ReviewResultView`(ai_panel.dart 现成渲染)、`AiResponseParser.parseReview`、`MapDiagnosis`。这些已造好但**从没接屏**,本计划把它们接进复盘屏。

**Architecture:**
- 数据汇总纯派生:`reviewStatsProvider`(StreamProvider over `watchAll` + selectedDate)→ `ReviewStats`{todayDone/todayTomato/todayTooHard + mapOverall:MapDiagnosis}。今日=createdAt 在 selectedDate 当天;mapOverall=全部 tooHard.reason 计数。复用既有 `streakProvider`/`pointsProvider` 作背景。
- AI 洞察:`reviewControllerProvider` 收集「仍 pending 且 downgradeLevel>0」的挣扎任务(标题+主因)→ 描述串 → `ai.review(...)`(isActive 才调,否则返回禁用态);打日志同 tooHard。
- UI:新建 `lib/features/review/review_screen.dart`(ConsumerStatefulWidget,持 AI 结果/loading)替换 `placeholder_screens.dart` 里的 `ReviewScreen`;`home_shell` 改导入。

**范围边界(不做):** 日历切换/历史某天复盘(本期只「今日+累计」,selectedDate 现恒今天);积分/番茄时间曲线图;prioritize(四象限)接屏;复盘结果落库缓存(每次按钮现算)。

**Tech Stack:** Flutter 3.44/Dart 3.12;riverpod 3.x;drift 2.33;flutter_test。
**工程根:** `frontend/promptme-app/`。分支 `feat/v1-review-screen`。前置:1.1–1.7+AI 开关+MAP 降级+MAP 诊断 已在 master。
**⚠️ 测试带代理前缀;别 flutter clean;widget 测试遇持续动画用显式 pump 不用 pumpAndSettle。**

---

### Task 1: ReviewStats + reviewStatsProvider(数据汇总聚合)
**Files:** Create `lib/domain/review/review_stats.dart`;Modify `lib/state/providers.dart`;Test `test/state/review_stats_provider_test.dart`
- [ ] 失败测试(内存 DB):插 1 捕获 + 完成 1 + 番茄 1 + 同因 tooHard×2 → `reviewStatsProvider` 的 todayDone/todayTomato/todayTooHard 计数正确、mapOverall.dominant 正确。
- [ ] `ReviewStats` 持有计数 + mapOverall(MapDiagnosis);`reviewStatsProvider` 用 watchAll+selectedDate 聚合。
- [ ] 通过 → 提交。

### Task 2: 复盘屏数据汇总 UI(替换占位)
**Files:** Create `lib/features/review/review_screen.dart`;Modify `lib/features/shell/home_shell.dart`、`lib/features/shell/placeholder_screens.dart`(删 ReviewScreen);Test `test/features/review/review_screen_test.dart`
- [ ] 失败测试:pump ReviewScreen(override databaseProvider+sharedPrefs)→ 显「今日」「连续」等汇总标签;有完成事件时显数字。
- [ ] 实现:今日卡(✓完成/🍅/😣太难了)+ 背景卡(🔥连续·★总积分·MAP 主因或「暂无明显模式」)。AI 区先留按钮占位(Task 3 填)。
- [ ] home_shell 导入改 review/review_screen.dart;analyze+test → 提交。

### Task 3: AI 复盘洞察(按钮 + ReviewResultView)
**Files:** Create `lib/state/review_controller.dart`;Modify `lib/features/review/review_screen.dart`;(复用 ai_panel.dart 的 ReviewResultView)
- [ ] `ReviewController.generate()`:收集 pending&downgradeLevel>0 任务的描述 → isActive?ai.review:禁用态;打日志。
- [ ] ReviewScreen:「生成 AI 复盘」按钮 → loading → ReviewResultView 显结果;关 AI 时按钮置灰 + 「去设置开启 AI」提示。
- [ ] 测试:AI 关闭时按钮态/提示(不实际联网);全量 test+analyze → 提交。

## 完成判据
- analyze 无 issue;test 全绿。
- 复盘 Tab 不再是占位:显今日完成/番茄/太难了 + 连续/积分/MAP 主因;点按钮(开 AI)出 AI 复盘建议,关 AI 给引导。
- 纯派生汇总无新 schema;AI 仅按钮触发、门控 isActive。

## 衔接
日历切换看历史某天;积分/番茄曲线;AI 结果缓存;prioritize 接屏。
