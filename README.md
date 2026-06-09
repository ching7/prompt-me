<div align="center">

# 🌱 PromptMe

**把想法变成行动的引擎。**
*Prompt Yourself Into Action.*

基于福格行为模型（Fogg Behavior Model · B=MAP）+ GTD 的**个人行为操作系统**——
不是又一个日历，而是把「想到」变成「持续做到」的随身教练。

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/平台-Android-3DDC84?logo=android&logoColor=white)
![Tests](https://img.shields.io/badge/tests-62%20passing-success)
![Status](https://img.shields.io/badge/状态-WIP%20·%20V1%20阶段1-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## 📖 这是什么

普通待办软件记录**任务**；PromptMe 关心的是行为本身：

> **怎么零摩擦地记下来 · 卡住时怎么变小 · 怎么持续做到。**

真实痛点不是「忘了」（提醒解决不了），而是「想法太多、不知道下一步、记录太麻烦」。所以 PromptMe 把流程收敛成一条**捕获 → 整理 → 执行 → 复盘**的链路：

```
随手捕获（手记／未来：桌面热键）
   → 收件箱（先收集，不打断）
   → 加入今日（整理）
   → 待办执行：我做到了 / 太难了 → 庆祝 / 无底线降级
   → 番茄钟专注
   → 复盘
```

> **V1 转向**：V0 曾走「飞书四象限 + 苹果日历」的规划导入路线，自测后发现「Demo 做完自己都不想打开」——于是砍掉日历订阅 / 飞书导入 / 四象限，收敛为**以捕获和执行为核心**的引擎。

## 💡 核心理念：B = M · A · P

行为发生 = **动机(Motivation) × 能力(Ability) × 提示(Prompt)**。PromptMe 把它落进每一个交互：

| 要素 | 在 PromptMe 中 |
| --- | --- |
| **P** 提示 | 本地通知 + 锁屏常驻微习惯提示 |
| **A** 能力 | 右滑 `太难了` → **无底线降级**成 2 分钟微习惯；番茄钟降低启动门槛 |
| **M** 动机 | 左滑 `我做到了` → 彩纸庆祝 + 连续天数；番茄完成 +🍅 |
| **B** 调试 | 选「太难了」的原因即给行为打 P/A/M 标，喂给复盘（规划中：AI 诊断 + 数据分析） |

> **点睛交互**：右滑 `太难了` → 一行选原因（忘记🌫️/太累🪫/没动力🫥，对应 P/A/M）→ 任务「无底线降级」成一个 2 分钟、几乎不可能失败的微习惯，并刷到锁屏。降低门槛不是放弃，是福格法则。

## ✨ 功能

**✅ 已实现（V1 · 阶段 1.1–1.6，手机端）**
- 📥 **收件箱**：手记零摩擦捕获（文本 + 领域标签，默认选中）；按标签过滤；**一键全部加入今日**；单条左滑删 / 右滑加入今日
- ✅ **待办（今日执行）**：今日待办 + 已完成两区；顶部日期 + 紧凑 stats（🔥连续天数 / ◎今日完成）；任务卡 = 领域色标 + 面包屑 + 圆圈勾选完成 + 逾期态；FAB 随手加任务
- 🔁 **福格闭环（滑动）**：左滑 `我做到了` → 全屏彩纸庆祝 + 连续天数；右滑 `太难了` → 压缩版 P/A/M 小弹窗 → **无底线降级**成 2 分钟微习惯（卡片变样 + 锁屏通知）
- 🍅 **番茄钟**：每任务点 🍅 进专注屏（25 分倒计时环 + 暂停 / 放弃）；到点 +1 🍅
- 🏷️ **领域标签**：工作 / 自媒体 / 学习 / 家庭 + 自定义，捕获/新建时即可打
- 🔔 本地通知 + 锁屏微习惯提示
- 💾 本地优先存储（SQLite / Drift），全 TDD（**62 个测试**）

**🚧 规划中（V1 后续阶段 + 阶段②）**
- [ ] 正反馈积分系统（捕获/完成/番茄都攒分 + 跳动动画）
- [ ] **AI**：MAP 诊断标签（异步分析任务是否合理/满足 M·A·P）+ 待办屏提示横幅
- [ ] **复盘屏**：每日数据分析（🍅/任务/完成率/专注时长 + 日历切换）+ AI 整理/复盘
- [ ] 完整 GTD 智能清单（下一步 / 即将到来 / 将来也许）
- [ ] **阶段②** 桌面零摩擦捕获（macOS 托盘 + 全局热键）→ ntfy 单/双向同步 → 手机；桌面番茄钟置顶小窗

## 🛠️ 技术栈

| 层 | 选型 |
| --- | --- |
| 客户端 | **Flutter**（安卓优先） |
| 状态管理 | **Riverpod** 3.x |
| 本地数据库 | **Drift**（类型安全 SQLite，`sqlite3_flutter_libs` 打包原生库） |
| 动画 | confetti（庆祝彩纸） |
| AI（接入中） | 自带 Key 直连，**OpenAI 兼容协议**（讯飞 MaaS / DeepSeek / Qwen 等） |
| 同步（阶段②） | **ntfy**（无账号 HTTP 推送）桌面↔手机 |
| 工程方法 | spec → 高保真原型 → **TDD 实现计划** → subagent 驱动实现 + 两段式审查 |

## 📂 项目结构

```
prompt-me/
├── frontend/
│   └── promptme-app/        # Flutter App（安卓优先）
│       ├── lib/
│       │   ├── domain/      # 纯逻辑：枚举 / 领域标签 / 福格降级 / AI（TDD）
│       │   ├── data/        # Drift 表 + DAO
│       │   ├── state/       # Riverpod providers + controllers
│       │   ├── features/    # inbox / todo / shell（3-Tab）/ settings
│       │   └── theme/       # 暖调纸感主题 + 领域色
│       └── test/            # 单元 + widget 测试（62 个）
├── backend/                 # 后端（阶段②，预留）
└── docs/
    └── superpowers/         # 设计 spec · 高保真原型 · 各阶段实现计划
```

## 🚀 快速开始

**前置**：[Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+、Android Studio + SDK，一台安卓真机或模拟器。

```bash
git clone <repo> && cd prompt-me/frontend/promptme-app

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 Drift 代码
flutter test                                                # 62 个用例
flutter run                                                 # 跑到设备上
```

> 🇨🇳 **国内网络与工具链提示（重要）**
> - **pub 镜像**：`export PUB_HOSTED_URL=https://pub.flutter-io.cn FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
> - **`flutter test` 必须排除 localhost 代理**，否则 `flutter_tester` 连本地端口被代理拦截、测试全崩：
>   `export no_proxy=127.0.0.1,localhost,::1 NO_PROXY=127.0.0.1,localhost,::1`
> - **sqlite3 原生库**默认从 GitHub 下载预编译 `.so`，国内常超时。首次安卓构建挂 VPN 代理下载一次即缓存（`export https_proxy=http://127.0.0.1:7897`，端口按你的代理）；之后无需代理。**别随意 `flutter clean`**（会清掉缓存的 `.so`）。
> - Gradle 阿里云/腾讯镜像已写进 `android/`。

## 🗺️ 路线图

**阶段 ①（手机重构，进行中）**
- [x] **1.1** 数据层地基（捕获来源 / 领域标签 / Inbox·今日 DAO）
- [x] **1.2** 清理遗留 + 3-Tab 骨架（收件箱 / 待办 / 复盘）
- [x] **1.3** 收件箱屏（手记 / 标签 / 过滤 / 批量加今日 / 滑动）
- [x] **1.4** 待办屏（今日待办 / 已完成 / stats / 任务卡 / FAB）
- [x] **1.5** 福格闭环（我做到了→庆祝 / 太难了→降级微习惯）
- [x] **1.6** 番茄钟（专注屏 + 🍅）
- [ ] **1.7+** 正反馈积分 · MAP 诊断标签(AI) · 复盘(数据+AI)

**阶段 ②** 桌面捕获（托盘 + 热键）+ ntfy 同步 + 桌面番茄小窗

## 📚 设计文档

- [V1 设计 Spec](docs/superpowers/specs/2026-06-05-promptme-v1-capture-gtd-pivot.md)
- [V1 高保真原型（HTML）](docs/superpowers/prototypes/2026-06-05-promptme-v1-mockup.html)
- 各阶段 TDD 实现计划：`docs/superpowers/plans/2026-06-0*-promptme-v1-phase1.*.md`

## 🙏 致谢

- **BJ Fogg** —— 福格行为模型（B=MAP）与《Tiny Habits》微习惯，本项目的理论根基。
- **David Allen** —— GTD（Getting Things Done）的「收集与执行分离」。

## 📄 License

[MIT](LICENSE) © 2026 PromptMe

<div align="center"><sub>用提示驱动行动 · Prompt Yourself Into Action.</sub></div>
