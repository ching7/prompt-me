# PromptMe

基于福格行为模型(B=MAP)的跨端行为管理工具。完整设计见 `docs/superpowers/specs/2026-06-03-promptme-v0-design.md`。

- **北极星**：用户「自己每天真用得上」；技术选型「只求快、最少运维」，不为展示堆栈。
- **产品模型**：Mac 早晨在飞书(四象限任务)+苹果日历(时间块)规划；手机端只「提示+跟踪」，**绝不让用户重录**。

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

> **Flutter 工程根 = `frontend/promptme-app/`。** 第一波三套实现计划里所有 `lib/`、`test/`、`android/`、`pubspec.yaml` 路径及 `flutter`/`dart` 命令，都在该目录下执行（不是仓库根）。

## 当前状态

设计 spec、高保真原型、第一波三套 TDD 实现计划均已完成并提交（见 `docs/superpowers/`）。代码尚未开始；执行前需先装 Flutter SDK + 安卓工具链。
