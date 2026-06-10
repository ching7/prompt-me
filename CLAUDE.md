# PromptMe

基于福格行为模型(B=MAP)+ GTD 的行为管理工具——**把想法变成行动的引擎**。当前设计见 `docs/superpowers/specs/2026-06-05-promptme-v1-capture-gtd-pivot.md`（V1 转向稿；旧 v0 设计已废弃）。

- **北极星**：作者「自己每天真用得上」；技术选型「只求快、最少运维」，不为展示堆栈。
- **产品模型(V1)**：链路 = **捕获 → 收件箱 → 加入今日 → 待办执行(福格闭环 + 番茄钟) → 复盘**。手机端 3 Tab(收件箱/待办/复盘)。桌面零摩擦捕获 + ntfy 同步是**阶段②**。
- **V1 转向**：已砍掉 v0 的苹果日历订阅 / 飞书 md 导入 / 四象限；改以捕获+执行为核心。**绝不让用户重录**。

## 目录结构约定（后续代码仓遵循）

顶层按 `backend / frontend / docs` 三分；`backend` 与 `frontend` 各自再「分模块」：

```
prompt-me/
├── backend/                后端代码，分模块（第二波：飞书 OAuth token 代理 / serverless）
├── frontend/               前端代码，分模块
│   └── promptme-app/       Flutter App（安卓优先，第一波主体）
└── docs/
    ├── api-spec/           接口文档
    ├── architecture/       架构设计
    ├── db-design/          数据库设计
    ├── prd/                产品资料：操作手册、需求规格说明书
    ├── test/               测试要求、规范
    └── superpowers/        设计 / 原型 / 实现计划（已有：spec、prototype、plans）
```

> **Flutter 工程根 = `frontend/promptme-app/`。** 所有 `lib/`、`test/`、`android/`、`pubspec.yaml` 路径及 `flutter`/`dart` 命令都在该目录下执行（不是仓库根）。

`lib/features/` 已分 `inbox / todo / shell / settings`；`state/` 有 `inbox_controller`/`todo_controller`/`today_controller`/`providers`；数据层 `data/`（Drift,schema v3）。

## 当前状态（V1 阶段①，master）

已实现 **1.1–1.7**（subagent 驱动 + 两段式审查，**68 个测试全绿**）：数据层地基 → 清理遗留+3-Tab 骨架 → 收件箱屏 → 待办屏(今日执行) → 福格闭环(我做到了/太难了滑动+庆祝+降级) → 番茄钟 → **正反馈积分**(捕获+2/完成+10/番茄+10，**事件派生总积分**=`TaskEventType` 加 `capture`/`tomato` + `ScoreCalculator` 求和，无可变计数器；`StatsChip ★总积分` 响应式 + 庆祝层 `+N 分`)。另含 **web 适配**(Drift WASM，`lib/data/connection/` 按平台条件导入，`web/` 资源随仓库；作者改用 Chrome 网页自测)。各阶段 TDD 计划在 `docs/superpowers/plans/2026-06-0*-promptme-v1-phase1.*.md`。**待做**：MAP 诊断标签(AI) · 复盘(数据+AI)；阶段② 桌面捕获+ntfy。

## ⚠️ 本机工具链坑（跑 flutter 必读）

我的 Bash 是 bash、不读用户 `~/.zshrc`,所以每条 `flutter`/`dart` 命令都要显式带前缀:
```
export PATH="/Users/chenyanan/development/flutter/flutter/bin:$PATH" PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn no_proxy=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn NO_PROXY=127.0.0.1,localhost,::1,pub.flutter-io.cn,storage.flutter-io.cn
```
- **`no_proxy` 必须含 `127.0.0.1,localhost`** —— 否则 Claude 自带代理(`42.192.60.90:31546`)会拦截 `flutter_tester` 的 localhost 连接 → 测试全 `Connection reset`、崩。
- **sqlite3 原生 `.so`** 从 GitHub 下载,国内直连超时;已下载缓存在 `.dart_tool`。**别 `flutter clean`**(会清缓存、又要联网下;真要下用用户 VPN `127.0.0.1:7897` 挂 `https_proxy`)。曾试 `source: system` 让安卓用系统库 → 运行态 `dlopen libsqlite3.so not found`,已回退,**安卓只能用默认下载模式**。
- 改 Drift 表后跑 `dart run build_runner build --delete-conflicting-outputs`(带上面前缀)。
- 测试归用户手动验收;我跑 build/analyze/test 仅自检,别声称「已为你验证」。
