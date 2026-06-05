# PromptMe v1 设计 —— 桌面捕获 + GTD + 福格对抗(MVP 转向)

> 状态:设计已确认,待写实现计划
> 日期:2026-06-05
> 前作:[v0 设计](2026-06-03-promptme-v0-design.md)(本文是对 v0 的方向性收敛与删减,不是推翻)

## 1. 背景与动机

v0「第一波」做完后,作者自测得出一个关键信号:**Demo 做完,自己都没有每天打开的欲望**。复盘后认定这不是功能不够,而是**价值假设**错位:

- v0 解决的是「我忘了」(提醒);作者的真实痛点是「**想法太多、不知道下一步、记录太麻烦**」(执行 + 收集)。
- 作者是重度知识工作者 / 架构师,真实工作流是「**输入发生在电脑、执行发生在手机**」;而 v0 的输入(飞书 md 粘贴、日历订阅)仍偏「规划优先」,摩擦大。
- 北极星不变:**自己每天真用得上;最少运维**。

**转向**:从「日程提醒工具」收敛为「**把想法变成行动的引擎**」——电脑零摩擦捕获,手机负责整理与执行,AI 在该出现的地方出现。

## 2. 产品定位

> **PromptMe = 把想法变成行动的引擎。**
> 电脑随手捕获 → 手机 Inbox 整理 → 今日执行(福格对抗)→ 正反馈 / 复盘。

链路:

```
电脑敲一句(全局热键)
   → ntfy(HTTP 推送)
   → 手机 Inbox(收件箱)
   → 加入今日
   → 我做到了 / 太难了→无底线降级
   → 连续天数 / AI 复盘
```

三套理论的分工:

- **GTD**:Capture(电脑捕获)→ Inbox → Clarify/Organize(加入今日)→ Do(今日执行)→ Review(复盘)。
- **福格 B=MAP**:今日执行屏的对抗闭环——`太难了`降 Ability,`我做到了`+连续天数喂 Motivation,通知/锁屏是 Prompt。
- **AI**:只在「复盘」屏出现(整理今日 / 复盘未完成),有明确存在理由,不滥用。

## 3. 范围

### 3.1 新增
- 桌面捕获:Flutter macOS 托盘 + 全局热键 → 输入框 → POST 到 ntfy。
- 手机 Inbox(收件箱)+ ntfy 拉取摄入。
- 手机端 3 Tab 信息架构(Inbox / 今日 / 复盘)。
- 设置页「捕获同步」卡(ntfy server / topic / 立即拉取 / 上次同步时间)。

### 3.2 删除(功能删减)
- **苹果日历订阅**:`CalendarDao`、`CalendarSubscriptionService`、`ics_parser`、`schedule_section`(日程区)、订阅设置卡;`Subscriptions` / `CalendarEvents` 表。
- **飞书导入**:`feishu_importer`、`feishu_markdown_parser`、`feishu_import_sheet`、飞书设置卡及相关测试。
- **四象限 UI**:`quadrant_section`、今日页的象限分组;`Quadrant` 在 UI 层不再出现。

### 3.3 保留
- **统计正反馈**:连续天数 / 今日完成率(`stats_header`)。
- **福格闭环**:`我做到了`(庆祝 + 连续天数)、`太难了`(选原因 P/A/M → 无底线降级 → 2 分钟微习惯)、已完成清单(点重开 / 右滑删除)。
- **AI**:`prioritize`(整理今日)、`review`(复盘未完成)、`downgrade`(降级文案)+ AI 设置卡(OpenAI 兼容,讯飞/DeepSeek/Qwen 预设 + 测试连接)。
- **本地通知**。

## 4. 手机端信息架构(底部 3 Tab)

### Tab ① 收件箱 Inbox
- 列出捕获原样条目:桌面经 ntfy 来的 + 手机 `+` 手记的。
- 每条:点开 →「加入今日 / 删除」。
- 进 App / 下拉 / 回前台 → 从 ntfy 拉新捕获写入。
- Tab 上带未读数(Inbox 条数)。
- 排序:按 id 倒序(新→旧),不引入新列。

### Tab ② 今日 Today(执行)
- 顶部:**连续天数 / 今日完成率**(正反馈,保留 `stats_header`)。
- 主体:**扁平**的今日行动清单(无四象限分组)。
- 每条:左滑 `我做到了`(庆祝 + 连续天数)· 右滑 `太难了`(选原因 → 无底线降级 → 微习惯)。
- 下方:已完成清单(点重开 / 右滑删除,分页加载)。
- `+`:在今日直接手记一条(进今日)。

### Tab ③ 复盘 Review(AI)
- `AI 整理今日`:对今日 / Inbox 给优先级与聚焦建议。
- `AI 复盘未完成`:定位 M/A/P 哪项塌了并给修法。
- AI 仅此屏出现。

> 备选(未采纳):单页「三块」(今日一件事 / 今天做了什么 / AI 复盘)。3 Tab 更贴 GTD 的「收集与执行分离」,故采用。

## 5. 桌面捕获 + ntfy 管道

### 5.1 桌面(Flutter macOS)
- 系统托盘常驻(`tray_manager`)。
- 全局热键(`hotkey_manager`,默认 `⌥Space`,可改)→ 弹无边框输入框。
- 回车 → `POST https://<server>/<topic>`,body = 捕获纯文本 → toast「已捕获」→ 自动隐藏;Esc 收起。
- 配置:ntfy server + topic(与手机共享同一 topic 口令)。
- 工程结构:独立的轻量 Flutter desktop 工程 `frontend/promptme-capture/`(避免把 desktop-only 依赖塞进手机 App);与手机端共享的只是 **ntfy 契约**(server / topic / 消息格式),POST 本身约十行,无需共享包。

### 5.2 手机(摄入)
- 进 App / 下拉 / 回前台 → `GET https://<server>/<topic>/json?poll=1&since=<lastId>`。
- 解析每条 message,按 ntfy 消息 id 去重 → 作为 Inbox 任务插入 → 更新 `lastId`。
- **无持久连接、无 FCM**,纯按需 HTTP 拉取。

### 5.3 契约
- 消息体:纯文本 = 捕获内容(MVP 不带结构)。
- `since`:上次已摄入的 ntfy 消息 id / 时间,存 prefs。

## 6. 数据模型(尽量复用,不大改库)

- **捕获条目 = `Task`**:`scheduledDate = null`、`source = TaskSource.capture`(枚举新增值,追加到末尾)、`title = 捕获文本`、`status = pending`。
- **Inbox 查询**:`scheduledDate IS NULL AND status = pending`,按 id 倒序(新增 `TaskDao.watchInbox()`)。
- **加入今日**:置 `scheduledDate = 今天`(条目即从 Inbox 移出、进入今日;复用现有 `watchTasksForDate`)。
- **四象限列**:`quadrant` 列保留但 UI 不再用,插入时给默认值(`importantUrgent`),避免库迁移;未来需要再以迁移移除。
- **同步游标**:`ntfy_topic`、`ntfy_server`、`ntfy_last_id` 存入 `SettingsController`(SharedPreferences)。

## 7. 设置页变更

- **删**:苹果日历订阅卡、飞书导入卡。
- **加**:「捕获同步」卡——ntfy server(默认 `https://ntfy.sh`)、topic(默认生成一长串随机串当口令)、「立即拉取」按钮、上次同步时间。
- **留**:AI 卡(不变)。

## 8. 实现阶段(各自 spec→plan→做,按序)

1. **阶段 1 · 手机重构(本设计先做这步)**
   删日历 / 飞书 / 四象限 → 3 Tab IA(Inbox / 今日 / 复盘)+ Inbox(先支持手机 `+` 手记)+ 扁平今日 + 保留统计 / 福格 / AI。**不依赖桌面,自己能跑通**,可独立验证「执行 > 规划」。
2. **阶段 2 · 桌面捕获 + ntfy**
   Flutter macOS 托盘 + 热键捕获 → ntfy → 手机 Inbox 拉取摄入 + 「捕获同步」设置卡。

## 9. 已知取舍 / 风险 / 未来

- **ntfy 公共 topic 明文可被猜到** → 用长随机串当口令;敏感内容后续自托管 ntfy 或加鉴权。
- **单向、按需拉取**:「捕获完晚上开 App 才看到」,无实时推送提醒(够验证;要实时再接 ntfy 推送 / FCM)。
- **删除量大**,但都在 git 历史,回退无忧。
- **未来**(本期不做,YAGNI):AI 自动 / 按需澄清(client 已具备)、浏览器插件收集箱、双向同步(Supabase 升级)、用机摩擦记录、AI 周复盘、跨端。

## 10. 验证标准(MVP 实验)

这是一次 MVP 实验,成败不看功能数量,看一个问题:

> **作者自己愿不愿意每天打开一次?** 连续自用一段时间后,捕获是否真的更勤、晚上是否真的会去执行。

成立,产品才真正开始;不成立,继续改假设而非加功能。
