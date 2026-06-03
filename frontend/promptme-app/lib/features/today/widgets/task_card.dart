import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.quadrant,
    required this.isMicro,
    required this.onDone,
    required this.onTooHard,
  });

  final String title;
  final Quadrant quadrant;
  final bool isMicro; // 已降级则换一种视觉
  final VoidCallback onDone;
  final VoidCallback onTooHard;

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
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMicro)
                        const _Badge(
                          text: '⚡ 2 分钟微习惯',
                          color: AppColors.leaf,
                          bg: Color(0x224F9D5E),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionBtn(
                              label: '我做到了',
                              filled: true,
                              icon: Icons.check,
                              onTap: onDone,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _ActionBtn(
                              label: isMicro ? '还是难' : '太难了',
                              filled: false,
                              icon: Icons.south,
                              onTap: onTooHard,
                            ),
                          ),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ink20, width: 1.5),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: filled ? AppColors.leaf : AppColors.q3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: filled ? AppColors.paper : AppColors.ink60)),
            ],
          ),
        ),
      ),
    );
  }
}
