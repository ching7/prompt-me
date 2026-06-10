import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_points.dart';

class StatsChip extends StatelessWidget {
  const StatsChip(
      {super.key,
      required this.streak,
      required this.done,
      required this.total,
      required this.points});
  final int streak;
  final int done;
  final int total;
  final int points;

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
        _sep(),
        AnimatedPoints(
            points: points,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.pop)),
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
