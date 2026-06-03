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
        ...tasks.map((t) => TaskCard(
              title: t.title,
              quadrant: t.quadrant,
              isMicro: microIds.contains(t.id),
              onDone: () => onDone(t.id),
              onTooHard: () => onTooHard(t.id),
            )),
      ],
    );
  }
}
