import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/ai/ai_models.dart';
import '../../domain/review/review_stats.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../state/review_controller.dart';
import '../../theme/app_colors.dart';
import '../today/widgets/ai_panel.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _loading = false;
  List<ReviewItem>? _items;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(reviewControllerProvider).generate();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(reviewStatsProvider).value;
    final streak = ref.watch(streakProvider).value ?? 0;
    final points = ref.watch(pointsProvider).value ?? 0;
    final aiActive = ref.watch(aiClientProvider).config.isActive;

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
            const SizedBox(height: 18),
            _sectionHeader('AI 复盘'),
            _aiSection(aiActive),
          ],
        ),
      ),
    );
  }

  Widget _aiSection(bool aiActive) {
    if (!aiActive) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('开启 AI 后可生成个性化复盘建议',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('去右上角「设置」打开「启用 AI」并填 key',
                style: TextStyle(fontSize: 12.5, color: AppColors.ink40)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_loading
                      ? '正在复盘…'
                      : (_items == null ? '生成 AI 复盘' : '重新生成')),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text('生成失败：$_error',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.q1)),
              ],
            ],
          ),
        ),
        if (_items != null && !_loading) ReviewResultView(items: _items!),
      ],
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
