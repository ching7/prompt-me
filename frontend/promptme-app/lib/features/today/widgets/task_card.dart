import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.quadrant,
    required this.isMicro,
  });

  final String title;
  final Quadrant quadrant;
  final bool isMicro; // 已降级则换一种视觉

  Color get _accent => switch (quadrant) {
        Quadrant.importantUrgent => AppColors.q1,
        Quadrant.importantNotUrgent => AppColors.q2,
        Quadrant.notImportantUrgent => AppColors.q3,
        Quadrant.notImportantNotUrgent => AppColors.q4,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMicro ? const Color(0xFFEAF3E9) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMicro ? const Color(0x554F9D5E) : AppColors.ink20,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: isMicro ? AppColors.leaf : _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMicro) ...[
                        const _Badge(
                          text: '⚡ 2 分钟微习惯',
                          color: AppColors.leaf,
                          bg: Color(0x224F9D5E),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.swipe, size: 13, color: AppColors.ink40),
                          SizedBox(width: 5),
                          Text('右滑太难了 · 左滑我做到了',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.ink40)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.bg});
  final String text;
  final Color color;
  final Color bg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
      );
}
