import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/ai/ai_models.dart';
import '../../domain/enums.dart';
import '../../domain/score/score_calculator.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_button.dart';
import '../inbox/capture_sheet.dart';
import '../today/widgets/celebration_overlay.dart';
import 'stats_chip.dart';
import 'focus_screen.dart';
import 'todo_card.dart';
import 'too_hard_sheet.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  // AI 整理今日：内联面板（非弹窗）。
  bool _aiOpen = false;
  bool _aiActive = false;
  bool _aiLoading = false;
  PrioritizeResult? _aiResult;
  String? _aiError;

  /// 手算「M月d日 · 周X」，避免依赖 intl locale 数据（widget 测试无需初始化）。
  String _dateLabel() {
    final n = DateTime.now();
    const wk = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${n.month}月${n.day}日 · ${wk[n.weekday % 7]}';
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        onCapture: (text, domain) {
          ref.read(todoControllerProvider).addToday(text: text, domain: domain);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// AI 整理今日：内联展开 → 关 AI 显引导；开 AI 顶部内联 loading → 四象限建议。
  Future<void> _runPrioritize() async {
    final active = ref.read(aiClientProvider).config.isActive;
    setState(() {
      _aiOpen = true;
      _aiActive = active;
      _aiError = null;
      _aiResult = null;
      _aiLoading = active;
    });
    if (!active) return;
    try {
      final r = await ref.read(todoControllerProvider).prioritizeToday();
      if (mounted) {
        setState(() {
          _aiResult = r;
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = '$e';
          _aiLoading = false;
        });
      }
    }
  }

  void _closeAi() => setState(() {
        _aiOpen = false;
        _aiResult = null;
        _aiError = null;
      });

  void _celebrate(int streak, {int? pointsDelta}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CelebrationOverlay(
        streak: streak,
        pointsDelta: pointsDelta,
        onDismiss: () => Navigator.of(ctx).maybePop(),
      ),
    );
  }

  Future<FailureReason?> _askReason(String title) {
    return showModalBottomSheet<FailureReason>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TooHardSheet(
        taskTitle: title,
        onReason: (r) => Navigator.of(context).pop(r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(todoTodayProvider);
    final streak = ref.watch(streakProvider).value ?? 0;
    final points = ref.watch(pointsProvider).value ?? 0;
    final ctl = ref.read(todoControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('出错了：$e')),
          data: (view) {
            return Column(
              children: [
                // 固定顶栏：日期 + AI 整理按钮 + 积分栏 同一行
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Text(_dateLabel(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink60)),
                      const SizedBox(width: 8),
                      _aiButton(),
                      const Spacer(),
                      StatsChip(
                          streak: streak,
                          done: view.doneCount,
                          total: view.totalCount,
                          points: points),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    children: [
                      if (_aiOpen) _aiPanel(),
                      _sectionHeader('★ 今日待办', '${view.pending.length} 件'),
                      if (view.pending.isEmpty)
                        _empty('今天还没排任务 · 按 + 加一件')
                      else
                        for (final t in view.pending) _pendingTile(ctl, t),
                      if (view.done.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader('已完成', '${view.done.length}'),
                        for (final t in view.done) _card(ctl, t, true),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _aiButton() => AiButton(
        key: const ValueKey('ai-prioritize'),
        label: 'AI 整理',
        loading: _aiOpen && _aiLoading,
        onPressed: _runPrioritize,
      );

  /// 内联 AI 整理面板（loading / 引导 / 结果），列表顶部。
  Widget _aiPanel() => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨ AI 整理今日',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const Spacer(),
                InkWell(
                  onTap: _closeAi,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: AppColors.ink40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!_aiActive)
              const Text('开启 AI 后可一键整理今日 · 去右上「设置」打开「启用 AI」并填 key',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink40))
            else if (_aiLoading)
              Row(children: const [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('正在整理今日…',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink60)),
              ])
            else if (_aiError != null)
              Text('整理失败：$_aiError',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.q1))
            else if (_aiResult != null)
              _PrioritizeInline(result: _aiResult!),
          ],
        ),
      );

  Widget _card(TodoController ctl, Task t, bool done,
      {String? diagnosisLabel}) {
    final title =
        (t.currentPromptText?.isNotEmpty ?? false) ? t.currentPromptText! : t.title;
    return TodoCard(
      title: title,
      domain: t.domain,
      done: done,
      overdue: !done && t.rolloverCount > 0,
      rolloverCount: t.rolloverCount,
      downgradeLevel: t.downgradeLevel,
      originTitle: t.title,
      diagnosisLabel: diagnosisLabel,
      tomatoDone: t.tomatoDone,
      tomatoEst: t.tomatoEst,
      onToggle: () => done ? ctl.reopen(t.id) : ctl.complete(t.id),
      onFocus: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              FocusScreen(taskId: t.id, taskTitle: title, tomatoEst: t.tomatoEst))),
    );
  }

  Widget _pendingTile(TodoController ctl, Task t) {
    final title = (t.currentPromptText?.isNotEmpty ?? false)
        ? t.currentPromptText!
        : t.title;
    final diagnosisLabel = ref.watch(taskDiagnosisProvider(t.id)).value?.label;
    return Dismissible(
      key: ValueKey('todo-${t.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        color: AppColors.q1, // 右滑 → 太难了（红）
        padding: const EdgeInsets.only(left: 20),
        child: const Text('太难了',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        color: AppColors.leaf, // 左滑 → 我做到了
        padding: const EdgeInsets.only(right: 20),
        child: const Text('我做到了 ✓',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          await ctl.complete(t.id);
          final fresh = await ctl.currentStreak(); // 完成后即时值，避免显示旧 streak
          if (mounted) {
            _celebrate(fresh, pointsDelta: ScoreCalculator.donePoints);
          }
          return true; // 从今日待办移除（stream 会把它放进已完成）
        } else {
          final reason = await _askReason(title);
          if (reason != null) await ctl.tooHard(t.id, reason);
          return false; // 不移除：降级后卡片经 stream 变微习惯
        }
      },
      child: _card(ctl, t, false, diagnosisLabel: diagnosisLabel),
    );
  }

  Widget _sectionHeader(String title, String count) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.ink)),
          const SizedBox(width: 9),
          Expanded(child: Container(height: 1, color: AppColors.ink20)),
          const SizedBox(width: 9),
          Text(count,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink40)),
        ]),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(text, style: TextStyle(color: AppColors.ink40))),
      );
}

/// AI 整理结果（内联紧凑版：今日先做 + 每条四象限建议）。
class _PrioritizeInline extends StatelessWidget {
  const _PrioritizeInline({required this.result});
  final PrioritizeResult result;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.todayFocus.isNotEmpty)
          Text('今天先做：${result.todayFocus.join('、')}',
              style: const TextStyle(
                  color: AppColors.q1, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        ...result.suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• ${s.taskTitle} → ${s.quadrant.label}（${s.reason}）',
                  style: const TextStyle(fontSize: 12.5)),
            )),
      ],
    );
  }
}
