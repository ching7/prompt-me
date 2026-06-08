import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../state/providers.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';
import '../inbox/capture_sheet.dart';
import 'stats_chip.dart';
import 'todo_card.dart';

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
                  for (final t in view.pending) _card(ctl, t, false),
                if (view.done.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionHeader('已完成', '${view.done.length}'),
                  for (final t in view.done) _card(ctl, t, true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(TodoController ctl, Task t, bool done) => TodoCard(
        title:
            (t.currentPromptText?.isNotEmpty ?? false) ? t.currentPromptText! : t.title,
        domain: t.domain,
        done: done,
        overdue: !done && t.rolloverCount > 0,
        rolloverCount: t.rolloverCount,
        onToggle: () => done ? ctl.reopen(t.id) : ctl.complete(t.id),
      );

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
