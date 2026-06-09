import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../state/providers.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';
import '../inbox/capture_sheet.dart';
import '../today/widgets/celebration_overlay.dart';
import 'stats_chip.dart';
import 'focus_screen.dart';
import 'todo_card.dart';
import 'too_hard_sheet.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  /// 手算「M月d日 · 周X」，避免依赖 intl locale 数据（widget 测试无需初始化）。
  String _dateLabel() {
    final n = DateTime.now();
    const wk = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${n.month}月${n.day}日 · ${wk[n.weekday % 7]}';
  }

  void _openAdd(BuildContext context, WidgetRef ref) {
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

  void _celebrate(BuildContext context, int streak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CelebrationOverlay(
        streak: streak,
        onDismiss: () => Navigator.of(ctx).maybePop(),
      ),
    );
  }

  Future<FailureReason?> _askReason(BuildContext context, String title) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todoTodayProvider);
    final streak = ref.watch(streakProvider).value ?? 0;
    final ctl = ref.read(todoControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('出错了：$e')),
          data: (view) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dateLabel(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink60)),
                    StatsChip(
                        streak: streak,
                        done: view.doneCount,
                        total: view.totalCount),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionHeader('★ 今日待办', '${view.pending.length} 件'),
                if (view.pending.isEmpty)
                  _empty('今天还没排任务 · 按 + 加一件')
                else
                  for (final t in view.pending) _pendingTile(context, ctl, t, streak),
                if (view.done.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionHeader('已完成', '${view.done.length}'),
                  for (final t in view.done) _card(context, ctl, t, true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, TodoController ctl, Task t, bool done) {
    final title =
        (t.currentPromptText?.isNotEmpty ?? false) ? t.currentPromptText! : t.title;
    return TodoCard(
      title: title,
      domain: t.domain,
      done: done,
      overdue: !done && t.rolloverCount > 0,
      rolloverCount: t.rolloverCount,
      tomatoDone: t.tomatoDone,
      tomatoEst: t.tomatoEst,
      onToggle: () => done ? ctl.reopen(t.id) : ctl.complete(t.id),
      onFocus: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FocusScreen(taskId: t.id, taskTitle: title))),
    );
  }

  Widget _pendingTile(
      BuildContext context, TodoController ctl, Task t, int streak) {
    final title = (t.currentPromptText?.isNotEmpty ?? false)
        ? t.currentPromptText!
        : t.title;
    return Dismissible(
      key: ValueKey('todo-${t.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        color: AppColors.q3, // 右滑 → 太难了
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
          if (context.mounted) _celebrate(context, streak);
          return true; // 从今日待办移除（stream 会把它放进已完成）
        } else {
          final reason = await _askReason(context, title);
          if (reason != null) await ctl.tooHard(t.id, reason);
          return false; // 不移除：降级后卡片经 stream 变微习惯
        }
      },
      child: _card(context, ctl, t, false),
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
