import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/review/review_stats.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reviewStatsProvider).value;
    final streak = ref.watch(streakProvider).value ?? 0;
    final points = ref.watch(pointsProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _sectionHeader('今日小结'),
            _todayCard(stats),
            const SizedBox(height: 18),
            _sectionHeader('累计'),
            _backgroundCard(streak, points, stats),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(ReviewStats? s) => _card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('✓ 完成', '${s?.todayDone ?? 0}', AppColors.leaf),
            _stat('🍅 番茄', '${s?.todayTomato ?? 0}', AppColors.q1),
            _stat('😣 太难了', '${s?.todayTooHard ?? 0}', AppColors.ink60),
          ],
        ),
      );

  Widget _backgroundCard(int streak, int points, ReviewStats? s) {
    final diag = s?.mapOverall.label;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('🔥 连续', '$streak 天', AppColors.q1),
              _stat('★ 总积分', '$points', AppColors.pop),
            ],
          ),
          const Divider(height: 22, color: AppColors.ink20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🩺 MAP 模式',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink60)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  diag ?? '暂无明显模式（再多几次「太难了」就能看出卡点）',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: diag != null ? AppColors.q1 : AppColors.ink40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.ink60)),
        ],
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.ink)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink20),
        ),
        child: child,
      );
}
