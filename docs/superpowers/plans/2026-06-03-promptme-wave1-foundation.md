# PromptMe 第一波 · 计划① 地基与核心逻辑 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭好 Flutter 安卓工程的地基，并用 TDD 完成所有纯函数核心逻辑（飞书 Markdown 解析、ICS 解析、连续天数/完成率、今日聚合、无底线降级、AI 提示与响应解析）与本地数据层（Drift 表 + DAO）。

**Architecture:** 分层但按职责切分小文件。`domain/` 全是不依赖 Flutter/IO 的纯 Dart（可纯单元测试）；`data/` 是 Drift 本地库；`theme/` 是视觉令牌。UI、网络、通知、AI 实网调用留给计划②③。本计划完成后：`flutter test` 全绿、App 能在安卓启动并显示占位首页。

**Tech Stack:** Flutter · Dart 3 (records/pattern matching) · Drift(SQLite) · Riverpod · google_fonts · intl · flutter_test

---

## Prerequisites（执行前确认，非代码步骤）

- 已安装 Flutter SDK（`flutter --version` 可用）、Android Studio / SDK，且 `flutter doctor` 安卓部分无致命错误。
- 有一台安卓真机（开发者模式 + USB 调试）或安卓模拟器。
- 在仓库根目录 `/Users/chenyanan/Desktop/prompt-me` 执行。该目录已有 `docs/` 与 git 历史；Flutter 工程将创建在仓库根（`flutter create .`）。

> 设计令牌（颜色/字体/文案）来源：`docs/superpowers/prototypes/2026-06-03-promptme-v0-mockup.html`。需求来源：`docs/superpowers/specs/2026-06-03-promptme-v0-design.md`。

## File Structure（本计划将创建的文件）

```
pubspec.yaml                                  # 依赖
lib/
  main.dart                                   # 入口
  app.dart                                    # MaterialApp + 主题 + 占位首页
  theme/
    app_colors.dart                           # 暖调纸感色板（来自原型）
    app_theme.dart                            # ThemeData + 字体
  domain/
    enums.dart                                # Quadrant / TaskStatus / TaskSource / TaskEventType / FailureReason
    parsing/
      parsed_task.dart                        # 解析产物
      feishu_markdown_parser.dart             # 飞书 MD -> 任务树（纯函数）
      parsed_event.dart
      ics_parser.dart                         # ICS -> 事件（纯函数）
    fogg/
      streak_calculator.dart                  # 连续天数 + 完成率（纯函数）
      today_aggregator.dart                   # 合并事件+任务为今日视图（纯函数）
      downgrade.dart                          # 无底线降级：本地兜底 + AI 提示（纯函数）
    ai/
      ai_models.dart                          # AI 结构化输出模型
      ai_prompts.dart                         # 提示词构造（纯函数）
      ai_response_parser.dart                 # 容错解析 AI JSON（纯函数）
  data/
    database.dart                             # Drift 表 + AppDatabase
    daos/
      task_dao.dart
      task_event_dao.dart
      calendar_dao.dart                       # CalendarEvents + Subscriptions
test/
  domain/enums_test.dart
  domain/parsing/feishu_markdown_parser_test.dart
  domain/parsing/ics_parser_test.dart
  domain/fogg/streak_calculator_test.dart
  domain/fogg/today_aggregator_test.dart
  domain/fogg/downgrade_test.dart
  domain/ai/ai_response_parser_test.dart
  domain/ai/ai_prompts_test.dart
  data/task_dao_test.dart
  data/task_event_dao_test.dart
  data/calendar_dao_test.dart
```

---

### Task 0: 脚手架、依赖与首次启动

**Files:**
- Create: 整个 Flutter 工程（`flutter create .` 生成 `lib/`, `android/`, `pubspec.yaml` 等）

- [ ] **Step 1: 在仓库根创建 Flutter 工程**

Run:
```bash
flutter create --org com.promptme --project-name promptme --platforms=android .
```
Expected: 生成 `android/`、`lib/main.dart`、`pubspec.yaml`；`docs/` 不受影响。

- [ ] **Step 2: 添加依赖**

Run:
```bash
flutter pub add flutter_riverpod drift sqlite3_flutter_libs path_provider path google_fonts intl http
flutter pub add dev:drift_dev dev:build_runner
```
Expected: `pubspec.yaml` 新增上述包，`flutter pub get` 成功。

- [ ] **Step 3: 设最低 SDK 与 Java 兼容（drift/sqlite3 需要）**

在 `android/app/build.gradle` 的 `defaultConfig` 内确保 `minSdkVersion` ≥ 21（如已是 flutter 默认 `flutter.minSdkVersion` 且 ≥21 则跳过；否则改为 `minSdkVersion 21`）。

- [ ] **Step 4: 首次启动验证脚手架**

Run:
```bash
flutter run -d android
```
Expected: 默认计数器 App 在安卓启动成功（确认工具链 OK）。停止运行。

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter android project + deps"
```

---

### Task 1: 视觉令牌与主题

**Files:**
- Create: `lib/theme/app_colors.dart`
- Create: `lib/theme/app_theme.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: 颜色板（取自原型）**

`lib/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

/// 暖调纸感色板，取自高保真原型。
class AppColors {
  static const paper = Color(0xFFF4EDDF);
  static const paper2 = Color(0xFFEFE6D4);
  static const card = Color(0xFFFBF6EC);
  static const ink = Color(0xFF24201A);
  static const ink60 = Color(0x9924201A);
  static const ink40 = Color(0x6624201A);
  static const ink20 = Color(0x2424201A);

  // 艾森豪威尔四象限
  static const q1 = Color(0xFFC4543A); // 重要紧急
  static const q1Tint = Color(0xFFF1DCD1);
  static const q2 = Color(0xFFC2892B); // 重要非紧急
  static const q2Tint = Color(0xFFF0E5C8);
  static const q3 = Color(0xFF3E7C77); // 不重要紧急
  static const q3Tint = Color(0xFFD7E5E2);
  static const q4 = Color(0xFF8A8B6F); // 不重要不紧急
  static const q4Tint = Color(0xFFE5E4D6);

  static const pop = Color(0xFFFF6A3D);  // 庆祝/动作强调
  static const leaf = Color(0xFF4F9D5E); // 完成/微习惯
}
```

- [ ] **Step 2: 主题与字体**

`lib/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const _zhFallback = ['PingFang SC', 'Noto Sans SC'];

  static ThemeData light() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final body = GoogleFonts.hankenGroteskTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamilyFallback: _zhFallback,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.q1,
        surface: AppColors.card,
      ),
      textTheme: body.copyWith(
        // Fraunces 用于大字/数字
        displayLarge: GoogleFonts.fraunces(
          textStyle: body.displayLarge,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: _zhFallback,
        ),
        headlineMedium: GoogleFonts.fraunces(
          textStyle: body.headlineMedium,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: _zhFallback,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: App 壳 + 占位首页**

`lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

class PromptMeApp extends StatelessWidget {
  const PromptMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PromptMe', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('记录每一次行动', style: TextStyle(color: AppColors.ink60)),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/main.dart`（整体替换）:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: PromptMeApp()));
}
```

- [ ] **Step 4: 静态检查**

Run: `flutter analyze`
Expected: No issues found（如有未用 import 警告，清理后再继续）。

- [ ] **Step 5: Commit**

```bash
git add lib/
git commit -m "feat: warm-journal theme + placeholder home"
```

---

### Task 2: 领域枚举

**Files:**
- Create: `lib/domain/enums.dart`
- Test: `test/domain/enums_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/enums_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';

void main() {
  group('Quadrant.fromLabel', () {
    test('matches plain and decorated labels', () {
      expect(Quadrant.fromLabel('重要紧急'), Quadrant.importantUrgent);
      expect(Quadrant.fromLabel('重要 · 紧急'), Quadrant.importantUrgent);
      expect(Quadrant.fromLabel('不重要不紧急'), Quadrant.notImportantNotUrgent);
      expect(Quadrant.fromLabel('随便'), isNull);
    });
    test('priority puts importantUrgent first', () {
      final sorted = [...Quadrant.values]..sort((a, b) => a.priority - b.priority);
      expect(sorted.first, Quadrant.importantUrgent);
    });
  });

  test('FailureReason maps to fogg factor', () {
    expect(FailureReason.forgot.foggFactor, 'P');
    expect(FailureReason.tired.foggFactor, 'A');
    expect(FailureReason.noMotivation.foggFactor, 'M');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/enums_test.dart`
Expected: 编译失败（`enums.dart` 不存在）。

- [ ] **Step 3: 实现**

`lib/domain/enums.dart`:
```dart
enum Quadrant {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent;

  String get label => switch (this) {
        Quadrant.importantUrgent => '重要紧急',
        Quadrant.importantNotUrgent => '重要非紧急',
        Quadrant.notImportantUrgent => '不重要紧急',
        Quadrant.notImportantNotUrgent => '不重要不紧急',
      };

  /// 排序权重：重要紧急最靠前（今日聚焦置顶）。
  int get priority => index;

  /// 容错匹配飞书标签：去掉空格与分隔符再比对。
  static Quadrant? fromLabel(String raw) {
    final s = raw.replaceAll(RegExp(r'[\s·•・\*#]'), '');
    return switch (s) {
      '重要紧急' => Quadrant.importantUrgent,
      '重要非紧急' => Quadrant.importantNotUrgent,
      '不重要紧急' => Quadrant.notImportantUrgent,
      '不重要不紧急' => Quadrant.notImportantNotUrgent,
      _ => null,
    };
  }
}

enum TaskStatus { pending, done }

enum TaskSource { manual, feishu }

enum TaskEventType { done, tooHard }

enum FailureReason {
  forgot,
  tired,
  noMotivation;

  String get label => switch (this) {
        FailureReason.forgot => '忘记',
        FailureReason.tired => '太累',
        FailureReason.noMotivation => '没动力',
      };

  /// 对应福格模型中塌掉的要素。
  String get foggFactor => switch (this) {
        FailureReason.forgot => 'P',
        FailureReason.tired => 'A',
        FailureReason.noMotivation => 'M',
      };
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/domain/enums_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/enums.dart test/domain/enums_test.dart
git commit -m "feat: domain enums (Quadrant/TaskStatus/.../FailureReason)"
```

---

### Task 3: 飞书 Markdown 解析器

**Files:**
- Create: `lib/domain/parsing/parsed_task.dart`
- Create: `lib/domain/parsing/feishu_markdown_parser.dart`
- Test: `test/domain/parsing/feishu_markdown_parser_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/parsing/feishu_markdown_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/parsing/feishu_markdown_parser.dart';

const _sample = '''
# 0603
## 重要紧急
- [ ] 整理广西农信问题
  - [ ] 智算定制功能查看与了解
  - [ ] 星火智能体功能核对
## 重要非紧急
- [ ] 郑州银行进度跟踪
# 0602
## 重要紧急
- [x] 整理人员投入情况
''';

void main() {
  test('parses dates, quadrants, nesting and done state', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);

    final gx = tasks.firstWhere((t) => t.title == '整理广西农信问题');
    expect(gx.quadrant, Quadrant.importantUrgent);
    expect(gx.date, DateTime(2026, 6, 3));
    expect(gx.done, isFalse);
    expect(gx.children.map((c) => c.title),
        ['智算定制功能查看与了解', '星火智能体功能核对']);

    final zz = tasks.firstWhere((t) => t.title == '郑州银行进度跟踪');
    expect(zz.quadrant, Quadrant.importantNotUrgent);

    final done = tasks.firstWhere((t) => t.title == '整理人员投入情况');
    expect(done.done, isTrue);
    expect(done.date, DateTime(2026, 6, 2));
  });

  test('only top-level tasks are returned as roots', () {
    final tasks = FeishuMarkdownParser.parse(_sample, year: 2026);
    expect(tasks.map((t) => t.title),
        containsAll(['整理广西农信问题', '郑州银行进度跟踪', '整理人员投入情况']));
    expect(tasks.any((t) => t.title == '智算定制功能查看与了解'), isFalse);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/parsing/feishu_markdown_parser_test.dart`
Expected: 编译失败（文件不存在）。

- [ ] **Step 3: 实现 ParsedTask**

`lib/domain/parsing/parsed_task.dart`:
```dart
import '../enums.dart';

class ParsedTask {
  final String title;
  final Quadrant quadrant;
  final DateTime? date;
  final bool done;
  final List<ParsedTask> children;

  ParsedTask({
    required this.title,
    required this.quadrant,
    this.date,
    this.done = false,
    List<ParsedTask>? children,
  }) : children = children ?? [];
}
```

- [ ] **Step 4: 实现解析器**

`lib/domain/parsing/feishu_markdown_parser.dart`:
```dart
import '../enums.dart';
import 'parsed_task.dart';

/// 把飞书文档导出的 Markdown 解析为「日期 + 四象限 + 嵌套 checkbox」的任务树。
class FeishuMarkdownParser {
  static final _checkbox = RegExp(r'^(\s*)[-*]\s*\[([ xX])\]\s+(.*)$');

  static List<ParsedTask> parse(String markdown, {required int year}) {
    final roots = <ParsedTask>[];
    final stack = <(int depth, ParsedTask task)>[];
    DateTime? currentDate;
    var currentQuadrant = Quadrant.importantNotUrgent; // 未声明象限时的默认桶

    for (final line in markdown.split('\n')) {
      if (line.trim().isEmpty) continue;

      final cb = _checkbox.firstMatch(line);
      if (cb != null) {
        final indent = cb.group(1)!.replaceAll('\t', '  ').length;
        final depth = indent ~/ 2;
        final done = cb.group(2)!.toLowerCase() == 'x';
        final title = cb.group(3)!.trim();
        final task = ParsedTask(
          title: title,
          quadrant: currentQuadrant,
          date: currentDate,
          done: done,
        );
        while (stack.isNotEmpty && stack.last.depth >= depth) {
          stack.removeLast();
        }
        if (stack.isEmpty) {
          roots.add(task);
        } else {
          stack.last.task.children.add(task);
        }
        stack.add((depth, task));
        continue;
      }

      final text = line
          .trim()
          .replaceAll(RegExp(r'^[#>*\s\-]+'), '')
          .replaceAll(RegExp(r'[*#\s]+$'), '');

      final date = _parseDate(text, year);
      if (date != null) {
        currentDate = date;
        stack.clear();
        continue;
      }
      final q = Quadrant.fromLabel(text);
      if (q != null) {
        currentQuadrant = q;
        stack.clear();
        continue;
      }
    }
    return roots;
  }

  static DateTime? _parseDate(String text, int year) {
    final m = RegExp(r'^(\d{1,2})月?(\d{1,2})日?$').firstMatch(text);
    if (m == null) return null;
    final mm = int.parse(m.group(1)!);
    final dd = int.parse(m.group(2)!);
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    return DateTime(year, mm, dd);
  }
}
```

- [ ] **Step 5: 运行确认通过**

Run: `flutter test test/domain/parsing/feishu_markdown_parser_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/parsing/parsed_task.dart lib/domain/parsing/feishu_markdown_parser.dart test/domain/parsing/feishu_markdown_parser_test.dart
git commit -m "feat: feishu markdown parser (date/quadrant/nesting/done)"
```

---

### Task 4: ICS 解析器

**Files:**
- Create: `lib/domain/parsing/parsed_event.dart`
- Create: `lib/domain/parsing/ics_parser.dart`
- Test: `test/domain/parsing/ics_parser_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/parsing/ics_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/parsing/ics_parser.dart';

const _ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:evt-1
SUMMARY:周报
DTSTART:20260603T020000Z
DTEND:20260603T033000Z
END:VEVENT
BEGIN:VEVENT
UID:evt-2
SUMMARY:芒种
DTSTART;VALUE=DATE:20260605
END:VEVENT
BEGIN:VEVENT
UID:evt-3
SUMMARY:长标题被折\\n行
 续行内容
DTSTART:20260603T090000
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('parses timed, all-day and folded events', () {
    final events = IcsParser.parse(_ics);
    expect(events.length, 3);

    final report = events.firstWhere((e) => e.uid == 'evt-1');
    expect(report.title, '周报');
    expect(report.allDay, isFalse);
    // 02:00Z 转本地后仍是同一时刻（仅校验解析成功且非空）
    expect(report.end, isNotNull);

    final allDay = events.firstWhere((e) => e.uid == 'evt-2');
    expect(allDay.allDay, isTrue);
    expect(allDay.start, DateTime(2026, 6, 5));

    final folded = events.firstWhere((e) => e.uid == 'evt-3');
    expect(folded.title.contains('续行内容'), isTrue);
    expect(folded.start, DateTime(2026, 6, 3, 9, 0, 0));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/parsing/ics_parser_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现 ParsedEvent**

`lib/domain/parsing/parsed_event.dart`:
```dart
class ParsedEvent {
  final String uid;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;

  ParsedEvent({
    required this.uid,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
  });
}
```

- [ ] **Step 4: 实现解析器**

`lib/domain/parsing/ics_parser.dart`:
```dart
import 'parsed_event.dart';

/// 极简 iCalendar 解析：满足苹果「已发布日历」订阅源（webcal）所需。
/// 处理：行折叠、VEVENT、UID/SUMMARY/DTSTART/DTEND、全天(VALUE=DATE)、UTC(Z)。
class IcsParser {
  static List<ParsedEvent> parse(String ics) {
    final lines = _unfold(ics);
    final events = <ParsedEvent>[];

    String? uid, summary;
    DateTime? start, end;
    var allDay = false;
    var inEvent = false;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = summary = null;
        start = end = null;
        allDay = false;
        continue;
      }
      if (line == 'END:VEVENT') {
        if (inEvent && start != null) {
          events.add(ParsedEvent(
            uid: uid ?? '${summary ?? 'evt'}_${start.millisecondsSinceEpoch}',
            title: summary ?? '(无标题)',
            start: start,
            end: end,
            allDay: allDay,
          ));
        }
        inEvent = false;
        continue;
      }
      if (!inEvent) continue;

      final idx = line.indexOf(':');
      if (idx < 0) continue;
      final rawKey = line.substring(0, idx);
      final value = line.substring(idx + 1);
      final key = rawKey.split(';').first.toUpperCase();

      switch (key) {
        case 'UID':
          uid = value.trim();
        case 'SUMMARY':
          summary = _unescape(value);
        case 'DTSTART':
          allDay = rawKey.toUpperCase().contains('VALUE=DATE') ||
              value.trim().length == 8;
          start = _parseDt(value);
        case 'DTEND':
          end = _parseDt(value);
      }
    }
    return events;
  }

  static List<String> _unfold(String ics) {
    final out = <String>[];
    for (final raw in ics.split(RegExp(r'\r?\n'))) {
      if ((raw.startsWith(' ') || raw.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] += raw.substring(1);
      } else {
        out.add(raw);
      }
    }
    return out;
  }

  static String _unescape(String v) => v
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');

  static DateTime? _parseDt(String value) {
    final s = value.trim();
    final date = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(s);
    if (date != null) {
      return DateTime(int.parse(date.group(1)!), int.parse(date.group(2)!),
          int.parse(date.group(3)!));
    }
    final dt =
        RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$').firstMatch(s);
    if (dt != null) {
      final y = int.parse(dt.group(1)!);
      final mo = int.parse(dt.group(2)!);
      final da = int.parse(dt.group(3)!);
      final h = int.parse(dt.group(4)!);
      final mi = int.parse(dt.group(5)!);
      final se = int.parse(dt.group(6)!);
      if (dt.group(7) == 'Z') {
        return DateTime.utc(y, mo, da, h, mi, se).toLocal();
      }
      return DateTime(y, mo, da, h, mi, se);
    }
    return null;
  }
}
```

- [ ] **Step 5: 运行确认通过**

Run: `flutter test test/domain/parsing/ics_parser_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/parsing/parsed_event.dart lib/domain/parsing/ics_parser.dart test/domain/parsing/ics_parser_test.dart
git commit -m "feat: minimal ICS parser (timed/all-day/folded VEVENT)"
```

---

### Task 5: 连续天数与完成率

**Files:**
- Create: `lib/domain/fogg/streak_calculator.dart`
- Test: `test/domain/fogg/streak_calculator_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/fogg/streak_calculator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/fogg/streak_calculator.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 6, day);

  test('counts consecutive days ending today', () {
    final days = {d(1), d(2), d(3)};
    expect(StreakCalculator.currentStreak(days, d(3)), 3);
  });

  test('a gap breaks the streak', () {
    final days = {d(1), d(3)};
    expect(StreakCalculator.currentStreak(days, d(3)), 1);
  });

  test('today empty but yesterday done keeps streak alive', () {
    final days = {d(1), d(2)};
    expect(StreakCalculator.currentStreak(days, d(3)), 2);
  });

  test('no activity yields zero', () {
    expect(StreakCalculator.currentStreak({}, d(3)), 0);
  });

  test('completion rate', () {
    expect(StreakCalculator.completionRate(done: 2, total: 5), closeTo(0.4, 1e-9));
    expect(StreakCalculator.completionRate(done: 0, total: 0), 0);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/fogg/streak_calculator_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现**

`lib/domain/fogg/streak_calculator.dart`:
```dart
class StreakCalculator {
  /// 从 [today] 往回数的连续「有完成」天数。
  /// 若今天还没完成，则从昨天起算，避免上午时段读成 0。
  static int currentStreak(Set<DateTime> completionDays, DateTime today) {
    final days = completionDays.map(_dateOnly).toSet();
    final t = _dateOnly(today);
    var cursor = days.contains(t) ? t : t.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// done / total，total 为 0 时返回 0。
  static double completionRate({required int done, required int total}) =>
      total == 0 ? 0 : done / total;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/domain/fogg/streak_calculator_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/fogg/streak_calculator.dart test/domain/fogg/streak_calculator_test.dart
git commit -m "feat: streak + completion-rate calculator"
```

---

### Task 6: 今日聚合

**Files:**
- Create: `lib/domain/fogg/today_aggregator.dart`
- Test: `test/domain/fogg/today_aggregator_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/fogg/today_aggregator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/today_aggregator.dart';

void main() {
  test('sorts events, groups pending tasks by quadrant, sinks done', () {
    final events = [
      TodayEvent(title: '周报', start: DateTime(2026, 6, 3, 10), allDay: false),
      TodayEvent(title: '复盘', start: DateTime(2026, 6, 3, 9), allDay: false),
    ];
    final tasks = [
      TodayTask(id: 1, title: '郑州银行', quadrant: Quadrant.importantNotUrgent, done: false),
      TodayTask(id: 2, title: '农信问题', quadrant: Quadrant.importantUrgent, done: false),
      TodayTask(id: 3, title: '人员投入', quadrant: Quadrant.importantUrgent, done: true),
    ];

    final view = TodayAggregator.build(events: events, tasks: tasks);

    expect(view.events.first.title, '复盘'); // 按时间排序
    expect(view.byQuadrant[Quadrant.importantUrgent]!.map((t) => t.title), ['农信问题']);
    expect(view.byQuadrant[Quadrant.importantNotUrgent]!.map((t) => t.title), ['郑州银行']);
    expect(view.completed.map((t) => t.title), ['人员投入']);
    expect(view.doneCount, 1);
    expect(view.totalCount, 3);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/fogg/today_aggregator_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现**

`lib/domain/fogg/today_aggregator.dart`:
```dart
import '../enums.dart';

class TodayEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarName;
  TodayEvent({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.calendarName,
  });
}

class TodayTask {
  final int id;
  final String title;
  final Quadrant quadrant;
  final bool done;
  TodayTask({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.done,
  });
}

class TodayView {
  final List<TodayEvent> events;
  final Map<Quadrant, List<TodayTask>> byQuadrant;
  final List<TodayTask> completed;
  final int doneCount;
  final int totalCount;
  TodayView({
    required this.events,
    required this.byQuadrant,
    required this.completed,
    required this.doneCount,
    required this.totalCount,
  });
}

class TodayAggregator {
  static TodayView build({
    required List<TodayEvent> events,
    required List<TodayTask> tasks,
  }) {
    final sortedEvents = [...events]..sort((a, b) => a.start.compareTo(b.start));

    final pending = tasks.where((t) => !t.done).toList();
    final completed = tasks.where((t) => t.done).toList();

    final byQuadrant = <Quadrant, List<TodayTask>>{};
    for (final q in Quadrant.values..sort((a, b) => a.priority - b.priority)) {
      final list = pending.where((t) => t.quadrant == q).toList();
      byQuadrant[q] = list;
    }

    return TodayView(
      events: sortedEvents,
      byQuadrant: byQuadrant,
      completed: completed,
      doneCount: completed.length,
      totalCount: tasks.length,
    );
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/domain/fogg/today_aggregator_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/fogg/today_aggregator.dart test/domain/fogg/today_aggregator_test.dart
git commit -m "feat: today aggregator (events + quadrant grouping + counts)"
```

---

### Task 7: 无底线降级（纯逻辑）

**Files:**
- Create: `lib/domain/fogg/downgrade.dart`
- Test: `test/domain/fogg/downgrade_test.dart`

- [ ] **Step 1: 写失败测试**

`test/domain/fogg/downgrade_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/fogg/downgrade.dart';

void main() {
  test('local fallback shrinks deterministically by level', () {
    final l1 = Downgrade.localFallback('整理广西农信问题', 1);
    final l2 = Downgrade.localFallback('整理广西农信问题', 2);
    expect(l1, contains('2 分钟'));
    expect(l1, contains('整理广西农信问题'));
    expect(l1, isNot(equals(l2)));
  });

  test('prompt mentions task, reason and fogg factor', () {
    final p = Downgrade.buildPrompt(
      taskTitle: '整理广西农信问题',
      reason: FailureReason.tired,
      level: 1,
    );
    expect(p, contains('整理广西农信问题'));
    expect(p, contains('太累'));
    expect(p, contains('A'));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/domain/fogg/downgrade_test.dart`
Expected: 编译失败。

- [ ] **Step 3: 实现**

`lib/domain/fogg/downgrade.dart`:
```dart
import '../enums.dart';

class Downgrade {
  /// AI 不可用时的确定性兜底；层级越高任务越小（无底线）。
  static String localFallback(String taskTitle, int level) {
    final clean = taskTitle.trim();
    return switch (level) {
      <= 1 => '只打开《$clean》，做满 2 分钟就停。',
      2 => '只看一眼《$clean》，读懂第一行就算赢。',
      _ => '现在对《$clean》说一句「我等下做」，然后深呼吸一次。',
    };
  }

  /// 让 AI 生成 2 分钟微习惯的提示词。
  static String buildPrompt({
    required String taskTitle,
    required FailureReason reason,
    required int level,
  }) {
    return '你是福格行为模型(Tiny Habits)教练。'
        '用户的任务「$taskTitle」没能完成，原因是「${reason.label}」'
        '（失败的福格要素是 ${reason.foggFactor}）。'
        '请把它"无底线降级"为一个 2 分钟内、几乎不可能失败的微习惯'
        '（当前降级层级 $level，层级越高越小）。'
        '只输出一行中文微习惯本身，不要任何解释或前缀。';
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/domain/fogg/downgrade_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/fogg/downgrade.dart test/domain/fogg/downgrade_test.dart
git commit -m "feat: downgrade fallback + AI prompt builder"
```

---

### Task 8: AI 提示词、模型与响应解析（纯逻辑）

**Files:**
- Create: `lib/domain/ai/ai_models.dart`
- Create: `lib/domain/ai/ai_prompts.dart`
- Create: `lib/domain/ai/ai_response_parser.dart`
- Test: `test/domain/ai/ai_prompts_test.dart`
- Test: `test/domain/ai/ai_response_parser_test.dart`

- [ ] **Step 1: 写失败测试（提示词）**

`test/domain/ai/ai_prompts_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/ai/ai_prompts.dart';

void main() {
  test('prioritize prompt lists tasks and events', () {
    final p = AiPrompts.prioritize(
      taskTitles: ['农信问题', '郑州银行'],
      todayEvents: ['10:00 周报'],
    );
    expect(p, contains('农信问题'));
    expect(p, contains('郑州银行'));
    expect(p, contains('周报'));
    expect(p, contains('四象限'));
  });

  test('review prompt lists overdue descriptions', () {
    final p = AiPrompts.review(overdueDescriptions: ['农信问题（被推迟3次，重要紧急）']);
    expect(p, contains('被推迟3次'));
  });
}
```

- [ ] **Step 2: 写失败测试（解析）**

`test/domain/ai/ai_response_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/domain/ai/ai_response_parser.dart';

void main() {
  test('parses prioritize JSON even when wrapped in prose/fences', () {
    const raw = '''
好的，这是结果：
```json
{
  "suggestions": [
    {"task": "农信问题", "quadrant": "重要紧急", "reason": "今天有deadline"}
  ],
  "todayFocus": ["农信问题"]
}
```
''';
    final r = AiResponseParser.parsePrioritize(raw);
    expect(r.suggestions.single.taskTitle, '农信问题');
    expect(r.suggestions.single.quadrant, Quadrant.importantUrgent);
    expect(r.todayFocus, ['农信问题']);
  });

  test('parses review JSON array', () {
    const raw =
        '[{"task":"农信问题","diagnosis":"任务太大","fogg":"A","suggestion":"拆成2分钟"}]';
    final items = AiResponseParser.parseReview(raw);
    expect(items.single.taskTitle, '农信问题');
    expect(items.single.foggFactor, 'A');
    expect(items.single.suggestion, '拆成2分钟');
  });
}
```

- [ ] **Step 3: 运行确认失败**

Run: `flutter test test/domain/ai/`
Expected: 编译失败。

- [ ] **Step 4: 实现模型**

`lib/domain/ai/ai_models.dart`:
```dart
import '../enums.dart';

class PrioritySuggestion {
  final String taskTitle;
  final Quadrant quadrant;
  final String reason;
  PrioritySuggestion({
    required this.taskTitle,
    required this.quadrant,
    required this.reason,
  });
}

class PrioritizeResult {
  final List<PrioritySuggestion> suggestions;
  final List<String> todayFocus;
  PrioritizeResult({required this.suggestions, required this.todayFocus});
}

class ReviewItem {
  final String taskTitle;
  final String diagnosis;
  final String foggFactor;
  final String suggestion;
  ReviewItem({
    required this.taskTitle,
    required this.diagnosis,
    required this.foggFactor,
    required this.suggestion,
  });
}
```

- [ ] **Step 5: 实现提示词**

`lib/domain/ai/ai_prompts.dart`:
```dart
class AiPrompts {
  static String prioritize({
    required List<String> taskTitles,
    required List<String> todayEvents,
  }) {
    final tasks = taskTitles.map((t) => '- $t').join('\n');
    final events = todayEvents.isEmpty ? '（今天无日程）' : todayEvents.map((e) => '- $e').join('\n');
    return '''
你是个人效率教练，使用艾森豪威尔四象限。
今天的日程：
$events

待办任务：
$tasks

请输出 JSON：
{"suggestions":[{"task":"任务原文","quadrant":"重要紧急|重要非紧急|不重要紧急|不重要不紧急","reason":"一句话理由"}],
"todayFocus":["最多3个今天必须先做的任务原文"]}
只输出 JSON。''';
  }

  static String review({required List<String> overdueDescriptions}) {
    final list = overdueDescriptions.map((d) => '- $d').join('\n');
    return '''
你是福格行为模型(B=MAP)教练。下面是用户未完成/过期的任务及信号：
$list

针对每条，判断失败的是 M(动机)/A(能力)/P(提示) 哪个，并给一个具体可执行的调整。
输出 JSON 数组：
[{"task":"任务原文","diagnosis":"原因","fogg":"M|A|P","suggestion":"一个具体调整"}]
只输出 JSON。''';
  }
}
```

- [ ] **Step 6: 实现容错解析**

`lib/domain/ai/ai_response_parser.dart`:
```dart
import 'dart:convert';
import '../enums.dart';
import 'ai_models.dart';

class AiResponseParser {
  /// 从可能包含散文/代码围栏的文本中抽出第一个 JSON 对象或数组。
  static String _extractJson(String raw, {required bool array}) {
    final open = array ? '[' : '{';
    final close = array ? ']' : '}';
    final start = raw.indexOf(open);
    final end = raw.lastIndexOf(close);
    if (start < 0 || end <= start) {
      throw const FormatException('no JSON found in AI response');
    }
    return raw.substring(start, end + 1);
  }

  static PrioritizeResult parsePrioritize(String raw) {
    final map = jsonDecode(_extractJson(raw, array: false)) as Map<String, dynamic>;
    final suggestions = ((map['suggestions'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map((e) => PrioritySuggestion(
              taskTitle: (e['task'] ?? '').toString(),
              quadrant: Quadrant.fromLabel((e['quadrant'] ?? '').toString()) ??
                  Quadrant.importantNotUrgent,
              reason: (e['reason'] ?? '').toString(),
            ))
        .toList();
    final focus = ((map['todayFocus'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    return PrioritizeResult(suggestions: suggestions, todayFocus: focus);
  }

  static List<ReviewItem> parseReview(String raw) {
    final list = jsonDecode(_extractJson(raw, array: true)) as List;
    return list.map((e) => e as Map<String, dynamic>).map((e) => ReviewItem(
          taskTitle: (e['task'] ?? '').toString(),
          diagnosis: (e['diagnosis'] ?? '').toString(),
          foggFactor: (e['fogg'] ?? '').toString(),
          suggestion: (e['suggestion'] ?? '').toString(),
        )).toList();
  }
}
```

- [ ] **Step 7: 运行确认通过**

Run: `flutter test test/domain/ai/`
Expected: All tests passed.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/ai/ test/domain/ai/
git commit -m "feat: AI prompts, models and tolerant JSON response parser"
```

---

### Task 9: Drift 数据库与表

**Files:**
- Create: `lib/data/database.dart`
- Generate: `lib/data/database.g.dart`（由 build_runner 生成）

- [ ] **Step 1: 写表与数据库定义**

`lib/data/database.dart`:
```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/enums.dart';
import 'daos/task_dao.dart';
import 'daos/task_event_dao.dart';
import 'daos/calendar_dao.dart';

part 'database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get parentTaskId => integer().nullable()();
  TextColumn get title => text()();
  IntColumn get quadrant => intEnum<Quadrant>()();
  IntColumn get source => intEnum<TaskSource>()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  IntColumn get estMinutes => integer().nullable()();
  IntColumn get status => intEnum<TaskStatus>().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get rolloverCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstScheduledDate => dateTime().nullable()();
  TextColumn get currentPromptText => text().nullable()();
  IntColumn get downgradeLevel => integer().withDefault(const Constant(0))();
}

class TaskEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get type => intEnum<TaskEventType>()();
  IntColumn get reason => intEnum<FailureReason>().nullable()();
  TextColumn get microVersionText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();
}

class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subscriptionId => integer().references(Subscriptions, #id)();
  TextColumn get uid => text()();
  TextColumn get title => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get calendarName => text().nullable()();
}

@DriftDatabase(
  tables: [Projects, Tasks, TaskEvents, Subscriptions, CalendarEvents],
  daos: [TaskDao, TaskEventDao, CalendarDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase(File(p.join(dir.path, 'promptme.sqlite')));
    });
  }
}
```

> 注：本步骤会因为 DAO 文件（Task 10/11/12）尚未创建而无法编译。**先创建三个 DAO 文件，再一次性 codegen。** 因此 Task 9 的代码生成放在 Task 12 末尾统一执行；本步先把 `database.dart` 写好提交。

- [ ] **Step 2: Commit（暂不 codegen）**

```bash
git add lib/data/database.dart
git commit -m "feat: drift tables + AppDatabase (codegen pending DAOs)"
```

---

### Task 10: TaskDao

**Files:**
- Create: `lib/data/daos/task_dao.dart`
- Test: `test/data/task_dao_test.dart`

- [ ] **Step 1: 实现 TaskDao**

`lib/data/daos/task_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../../domain/enums.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<Task?> getById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 某天的任务（按 scheduledDate 的日期部分匹配）。
  Future<List<Task>> tasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(start) &
              t.scheduledDate.isSmallerThanValue(end)))
        .get();
  }

  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(start) &
              t.scheduledDate.isSmallerThanValue(end)))
        .watch();
  }

  Future<void> markDone(int id, DateTime at) => (update(tasks)
        ..where((t) => t.id.equals(id)))
      .write(TasksCompanion(
    status: const Value(TaskStatus.done),
    completedAt: Value(at),
  ));

  Future<void> applyDowngrade(int id, String microText, int level) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        currentPromptText: Value(microText),
        downgradeLevel: Value(level),
      ));

  /// 所有已完成任务的「完成日期」集合（用于连续天数）。
  Future<Set<DateTime>> completionDays() async {
    final rows = await (select(tasks)
          ..where((t) => t.completedAt.isNotNull()))
        .get();
    return rows
        .map((r) => r.completedAt!)
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
  }
}
```

- [ ] **Step 2: 写测试**

`test/data/task_dao_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DateTime d(int day, [int h = 0]) => DateTime(2026, 6, day, h);

  test('insert, fetch by date, mark done, completion days', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '农信问题',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
      scheduledDate: Value(d(3)),
    ));

    final todays = await db.taskDao.tasksForDate(d(3));
    expect(todays.single.title, '农信问题');

    await db.taskDao.markDone(id, d(3, 17));
    final done = await db.taskDao.getById(id);
    expect(done!.status, TaskStatus.done);

    final days = await db.taskDao.completionDays();
    expect(days, contains(DateTime(2026, 6, 3)));
  });

  test('applyDowngrade updates prompt + level', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '农信问题',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
    ));
    await db.taskDao.applyDowngrade(id, '只打开清单，写一句话', 1);
    final t = await db.taskDao.getById(id);
    expect(t!.currentPromptText, '只打开清单，写一句话');
    expect(t.downgradeLevel, 1);
  });
}
```

> 该测试要等 codegen 后才能编译运行（见 Task 12 Step 3）。本任务先提交代码。

- [ ] **Step 3: Commit**

```bash
git add lib/data/daos/task_dao.dart test/data/task_dao_test.dart
git commit -m "feat: TaskDao + tests (codegen pending)"
```

---

### Task 11: TaskEventDao

**Files:**
- Create: `lib/data/daos/task_event_dao.dart`
- Test: `test/data/task_event_dao_test.dart`

- [ ] **Step 1: 实现**

`lib/data/daos/task_event_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../database.dart';

part 'task_event_dao.g.dart';

@DriftAccessor(tables: [TaskEvents])
class TaskEventDao extends DatabaseAccessor<AppDatabase> with _$TaskEventDaoMixin {
  TaskEventDao(super.db);

  Future<int> log(TaskEventsCompanion event) => into(taskEvents).insert(event);

  Future<List<TaskEvent>> forTask(int taskId) =>
      (select(taskEvents)..where((e) => e.taskId.equals(taskId))).get();

  Future<List<TaskEvent>> all() => select(taskEvents).get();
}
```

- [ ] **Step 2: 写测试**

`test/data/task_event_dao_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('logs done and too_hard events with reason', () async {
    final taskId = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '农信问题',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
    ));

    await db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: taskId,
      type: TaskEventType.tooHard,
      createdAt: DateTime(2026, 6, 3, 16),
      reason: const Value(FailureReason.tired),
      microVersionText: const Value('只打开清单，写一句话'),
    ));

    final events = await db.taskEventDao.forTask(taskId);
    expect(events.single.type, TaskEventType.tooHard);
    expect(events.single.reason, FailureReason.tired);
  });
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/daos/task_event_dao.dart test/data/task_event_dao_test.dart
git commit -m "feat: TaskEventDao + tests (codegen pending)"
```

---

### Task 12: CalendarDao + 统一代码生成 + 全量测试

**Files:**
- Create: `lib/data/daos/calendar_dao.dart`
- Test: `test/data/calendar_dao_test.dart`
- Generate: 所有 `*.g.dart`

- [ ] **Step 1: 实现 CalendarDao**

`lib/data/daos/calendar_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../database.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [Subscriptions, CalendarEvents])
class CalendarDao extends DatabaseAccessor<AppDatabase> with _$CalendarDaoMixin {
  CalendarDao(super.db);

  Future<int> addSubscription(SubscriptionsCompanion sub) =>
      into(subscriptions).insert(sub);

  Future<List<Subscription>> subscriptionsList() => select(subscriptions).get();

  /// 用最新拉取结果替换某订阅源的全部事件。
  Future<void> replaceEvents(int subscriptionId, List<CalendarEventsCompanion> events) async {
    await transaction(() async {
      await (delete(calendarEvents)
            ..where((e) => e.subscriptionId.equals(subscriptionId)))
          .go();
      await batch((b) => b.insertAll(calendarEvents, events));
    });
  }

  Future<List<CalendarEvent>> eventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where((e) =>
              e.start.isBiggerOrEqualValue(start) &
              e.start.isSmallerThanValue(end)))
        .get();
  }
}
```

- [ ] **Step 2: 写测试**

`test/data/calendar_dao_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('replaceEvents is idempotent per subscription', () async {
    final subId = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: 'https://x/ics', displayName: '工作'));

    CalendarEventsCompanion ev(String uid, int hour) =>
        CalendarEventsCompanion.insert(
          subscriptionId: subId,
          uid: uid,
          title: '周报',
          start: DateTime(2026, 6, 3, hour),
        );

    await db.calendarDao.replaceEvents(subId, [ev('a', 10), ev('b', 11)]);
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 2);

    // 再拉一次（替换，不应翻倍）
    await db.calendarDao.replaceEvents(subId, [ev('a', 10)]);
    expect((await db.calendarDao.eventsForDate(DateTime(2026, 6, 3))).length, 1);
  });
}
```

- [ ] **Step 3: 运行代码生成**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: 生成 `lib/data/database.g.dart`、`lib/data/daos/*.g.dart`，无错误。

- [ ] **Step 4: 跑全部测试**

Run: `flutter test`
Expected: 所有测试通过（domain + data 共 11 个测试文件）。

- [ ] **Step 5: 静态检查 + 启动**

Run: `flutter analyze`
Expected: No issues.
Run: `flutter run -d android`（确认仍能启动占位首页）后停止。

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: CalendarDao + drift codegen + green test suite"
```

---

## Self-Review

**Spec coverage（对照 spec §9 数据模型 / §10 模块 / §12 测试）：**
- Project / Task / TaskEvent / CalendarEvent / Subscription 五张表 → Task 9 全部覆盖（含 `rolloverCount`、`firstScheduledDate`、`currentPromptText`、`downgradeLevel`、`reason`、`microVersionText`）。✅
- 解析器（ics + 飞书 markdown）纯函数单测 → Task 3/4。✅
- 福格聚合（连续天数/完成率/今日）单测 → Task 5/6。✅
- 降级纯逻辑 + AI 提示/解析 → Task 7/8（实网调用留计划③）。✅
- 主题取自原型令牌 → Task 1。✅
- 本计划**不含**：今日 UI、`[做到了]/[太难了]` 交互、通知、订阅实网拉取、AI 实网调用、飞书粘贴导入 UI、设置页 → 均在计划②③。（有意为之，非遗漏。）

**Placeholder scan：** 无 TBD/TODO；每个代码步骤含完整代码与可运行命令。✅

**Type consistency：** `TaskDao.markDone/applyDowngrade/completionDays`、`CalendarDao.replaceEvents/eventsForDate`、`TaskEventDao.log/forTask`、枚举 `Quadrant.fromLabel/priority`、`FailureReason.label/foggFactor`、`TodayAggregator.build` 的签名在跨任务测试中一致引用。Drift 生成的 `Task`/`CalendarEvent`/`TaskEvent`/`Subscription` 数据类名与表名一致。✅

> **已知顺序约束**（已在文中标注）：`database.dart`(Task9) 依赖三个 DAO 文件，故 codegen 统一放在 Task 12 Step 3；Task 10/11 的测试在 codegen 后才能编译运行，Task 12 Step 4 统一验证。

---

## 下一步（计划②③，待写）

- **计划② 今日时间线与福格闭环 UI**：Riverpod providers（包装 DAO + TodayAggregator）→ 今日屏（顶部连续天数/完成环、日程、四象限任务）→ `[做到了]`(庆祝动画+markDone+TaskEvent) / `[太难了]`(原因弹层 → 本地兜底降级 → applyDowngrade + TaskEvent) → 手动新增任务。Widget 测试 + 一次安卓真机走查。
- **计划③ 集成**：日历订阅服务（http GET → IcsParser → CalendarDao.replaceEvents + 定时刷新）、飞书粘贴导入 UI（贴 MD → FeishuMarkdownParser → 落库）、AI 服务（BYO key 直连 + AiPrompts/AiResponseParser，整理今日 / 复盘未完成）、通知服务（定时 + 常驻『今日·重要紧急』+ 降级后刷新微习惯到锁屏）、设置页（订阅链接、AI provider/key）。
