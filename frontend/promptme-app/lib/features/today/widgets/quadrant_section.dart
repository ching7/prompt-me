import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../domain/fogg/today_aggregator.dart';
import '../../../theme/app_colors.dart';
import 'task_card.dart';

class QuadrantSection extends StatelessWidget {
  const QuadrantSection({
    super.key,
    required this.quadrant,
    required this.tasks,
    required this.microIds,
    required this.onDone,
    required this.onTooHard,
  });

  final Quadrant quadrant;
  final List<TodayTask> tasks;
  final Set<int> microIds; // 已降级的任务 id
  final void Function(int id) onDone;
  final void Function(int id) onTooHard;

  Color get _dot => switch (quadrant) {
        Quadrant.importantUrgent => AppColors.q1,
        Quadrant.importantNotUrgent => AppColors.q2,
        Quadrant.notImportantUrgent => AppColors.q3,
        Quadrant.notImportantNotUrgent => AppColors.q4,
      };

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _dot, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(quadrant.label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        ...tasks.map((t) => Dismissible(
              key: ValueKey('task-${t.id}'),
              // 右滑(startToEnd)→太难了；左滑(endToStart)→我做到了。
              // confirmDismiss 永远返回 false：滑动只作触发，卡片去留交给数据流刷新，
              // 既避免 Dismissible「仍在树中」断言，也让「太难了」后卡片能原地保留。
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.endToStart) {
                  onDone(t.id);
                } else {
                  onTooHard(t.id);
                }
                return false;
              },
              background: _swipeBg(
                  color: AppColors.q2,
                  icon: Icons.south,
                  label: '太难了',
                  alignLeft: true),
              secondaryBackground: _swipeBg(
                  color: AppColors.leaf,
                  icon: Icons.check,
                  label: '我做到了',
                  alignLeft: false),
              child: TaskCard(
                title: t.title,
                quadrant: t.quadrant,
                isMicro: microIds.contains(t.id),
              ),
            )),
      ],
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required bool alignLeft,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
