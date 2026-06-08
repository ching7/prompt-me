import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatsChip extends StatelessWidget {
  const StatsChip(
      {super.key, required this.streak, required this.done, required this.total});
  final int streak;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('🔥$streak',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        _sep(),
        Text('◎$done/$total',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.q3)),
      ]),
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 12,
        color: AppColors.ink20,
        margin: const EdgeInsets.symmetric(horizontal: 9),
      );
}
