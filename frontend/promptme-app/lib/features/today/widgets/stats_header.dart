import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.streak,
    required this.done,
    required this.total,
  });
  final int streak;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0.0 : done / total;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _box(
            label: '连续天数',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('$streak',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w700, height: 1)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('天',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.ink40)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _box(
            label: '今日完成',
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: rate,
                          strokeWidth: 7,
                          backgroundColor: AppColors.ink20,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.leaf),
                        ),
                      ),
                      Text('${(rate * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('$done/$total',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _box({required String label, required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink60)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}
