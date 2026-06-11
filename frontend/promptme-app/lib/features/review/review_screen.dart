import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/ai/ai_models.dart';
import '../../domain/review/daily_trend.dart';
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

  /// 已生成的 AI 复盘结果，按日期留存：切走再切回那天，内容仍在（不必重生成）。
  final Map<DateTime, List<ReviewItem>> _byDate = {};

  /// 点「AI 复盘」：内联展开（与待办「AI 整理」同逻辑）。关 AI → 引导。
  Future<void> _onAiTap(bool active) async {
    final date = ref.read(reviewDateProvider);
    final cached = _byDate[date];
    setState(() {
      _aiOpen = true;
      _error = null;
      _items = cached; // 有缓存先直接显示
      _loading = active && cached == null;
    });
    if (!active || cached != null) return; // 关 AI 显引导；有缓存不重打
    try {
      final items = await ref.read(reviewControllerProvider).generate();
      if (!mounted) return;
      _byDate[date] = items;
      if (ref.read(reviewDateProvider) == date) {
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

  /// 选中日期是否今天（标题/右箭头禁用判断）。
  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(reviewDateProvider);
    // 切换日期 → 恢复那天已生成的 AI 复盘（有缓存继续显示，无则收起）；内容不丢。
    ref.listen(reviewDateProvider, (prev, next) {
      if (prev == next) return;
      final cached = _byDate[next];
      setState(() {
        _items = cached;
        _error = null;
        _loading = false;
        _aiOpen = cached != null;
      });
    });
    final isToday = _isToday(date);
    final stats = ref.watch(reviewStatsForDateProvider(date)).value;
    final trend = ref.watch(dailyTrendProvider).value ?? const <DayStat>[];
    final streak = ref.watch(streakProvider).value ?? 0;
    final points = ref.watch(pointsProvider).value ?? 0;
    final aiActive = ref.watch(aiClientProvider).config.isActive;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // 小结表头：日期步进（看历史） + 右侧「AI 复盘」按钮（与待办同位置/同样式）
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  _DateStepper(
                    date: date,
                    isToday: isToday,
                    onPrev: () => ref.read(reviewDateProvider.notifier).shift(-1),
                    onNext: isToday
                        ? null
                        : () => ref.read(reviewDateProvider.notifier).shift(1),
                    onToday: isToday
                        ? null
                        : () => ref.read(reviewDateProvider.notifier).toToday(),
                  ),
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
            if (trend.isNotEmpty) ...[
              const SizedBox(height: 18),
              _sectionHeader('近 14 天'),
              _trendCard(trend, date),
            ],
            const SizedBox(height: 18),
            _sectionHeader('累计'),
            _backgroundCard(streak, points, stats),
          ],
        ),
      ),
    );
  }

  /// 近 14 天积分趋势条：每条点按 → 跳到那天小结；当天高亮、未来不显示。
  Widget _trendCard(List<DayStat> trend, DateTime selected) {
    final maxPoints =
        trend.fold<int>(1, (m, d) => d.points > m ? d.points : m);
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final first = trend.first.date;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('积分趋势',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink60)),
              const Spacer(),
              const Text('点按某天看小结',
                  style: TextStyle(fontSize: 10.5, color: AppColors.ink40)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in trend)
                  Expanded(
                    child: _TrendBar(
                      stat: d,
                      maxPoints: maxPoints,
                      selected: sameDay(d.date, selected),
                      isToday: _isToday(d.date),
                      onTap: () =>
                          ref.read(reviewDateProvider.notifier).set(d.date),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${first.month}/${first.day}',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.ink40)),
              const Spacer(),
              const Text('今天',
                  style: TextStyle(fontSize: 10, color: AppColors.ink40)),
            ],
          ),
        ],
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

/// 复盘日期步进：◀ 〔标题/日期〕 ▶ + 非今天时「今天」回跳。今天时右箭头禁用。
class _DateStepper extends StatelessWidget {
  const _DateStepper({
    required this.date,
    required this.isToday,
    required this.onPrev,
    this.onNext,
    this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  String _label() {
    if (isToday) return '今日小结';
    const wk = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${date.month}月${date.day}日 · ${wk[date.weekday % 7]}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.chevron_left, onPrev),
        GestureDetector(
          onTap: onToday,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(_label(),
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.ink)),
          ),
        ),
        _arrow(Icons.chevron_right, onNext),
        if (!isToday)
          GestureDetector(
            key: const ValueKey('review-today'),
            onTap: onToday,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.ink20),
              ),
              child: const Text('今天',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink60)),
            ),
          ),
      ],
    );
  }

  // 无涟漪（GestureDetector 而非 InkResponse）：避免 widget 测试里持续 ticker 卡死。
  Widget _arrow(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 20,
              color: onTap == null ? AppColors.ink20 : AppColors.ink60),
        ),
      );
}

/// 单日趋势条：高 ∝ 当日积分；选中=pop、今天=q3、有数=leaf、空=ink20。点按选中。
class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.stat,
    required this.maxPoints,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DayStat stat;
  final int maxPoints;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = maxPoints <= 0 ? 0.0 : stat.points / maxPoints;
    final h = stat.points == 0 ? 3.0 : 6.0 + ratio * 38.0; // 6..44
    final color = selected
        ? AppColors.pop
        : (isToday
            ? AppColors.q3
            : (stat.isEmpty ? AppColors.ink20 : AppColors.leaf));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selected && stat.points > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('${stat.points}',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pop)),
              ),
            Container(
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
