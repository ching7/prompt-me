import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/ai/ai_models.dart';
import '../../domain/review/review_stats.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../state/review_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_button.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _aiOpen = false;
  bool _loading = false;
  List<ReviewItem>? _items;
  String? _error;

  /// 点「AI 复盘」：内联展开（与待办「AI 整理」同逻辑）。关 AI → 引导。
  Future<void> _onAiTap(bool active) async {
    setState(() {
      _aiOpen = true;
      _error = null;
      _items = null;
      _loading = active;
    });
    if (!active) return;
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
            // 今日小结 + 右侧「AI 复盘」按钮（与待办「日期 + AI 整理」同位置/同样式）
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  const Text('今日小结',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.ink)),
                  const Spacer(),
                  AiButton(
                    key: const ValueKey('review-ai'),
                    label: 'AI 复盘',
                    loading: _loading,
                    onPressed: () => _onAiTap(aiActive),
                  ),
                ],
              ),
            ),
            _todayCard(stats),
            if (_aiOpen) ...[
              const SizedBox(height: 12),
              _aiPanel(aiActive),
            ],
            const SizedBox(height: 18),
            _sectionHeader('累计'),
            _backgroundCard(streak, points, stats),
          ],
        ),
      ),
    );
  }

  /// 内联 AI 复盘面板（引导 / loading / 结果），紧贴今日小结下方。
  Widget _aiPanel(bool aiActive) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!aiActive)
              const Text('开启 AI 后可生成个性化复盘建议 · 去右上「设置」打开「启用 AI」并填 key',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink40))
            else if (_loading)
              Row(children: const [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('正在复盘…',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink60)),
              ])
            else if (_error != null)
              Text('生成失败：$_error',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.q1))
            else if (_items != null && _items!.isEmpty)
              const Text('暂无挣扎中的任务，或数据还不够。',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink40))
            else if (_items != null)
              ..._items!.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i.taskTitle}（${i.foggFactor}）',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${i.diagnosis} → ${i.suggestion}',
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.ink60)),
                      ],
                    ),
                  )),
          ],
        ),
      );

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
