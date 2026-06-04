import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/enums.dart';
import '../../domain/fogg/today_aggregator.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../state/today_controller.dart';
import '../../theme/app_colors.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/ai_panel.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/quadrant_section.dart';
import 'widgets/schedule_section.dart';
import 'widgets/stats_header.dart';
import 'widgets/too_hard_sheet.dart';
import '../settings/settings_screen.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _celebrating = false;
  int _celebrateStreak = 0;

  // 已完成清单分页：每页 8 条，滚到底或点按钮再加载，避免整页无限变长。
  static const _completedPage = 8;
  final _scroll = ScrollController();
  int _completedLimit = _completedPage;
  int _completedTotal = 0;

  // 右滑删除时先本地隐藏，避免 Dismissible 在数据库流回写前报「仍在树中」断言。
  final Set<int> _removing = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_completedLimit >= _completedTotal) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      setState(() => _completedLimit += _completedPage);
    }
  }

  Future<void> _onDone(int id) async {
    await ref.read(todayControllerProvider).complete(id);
    final streak = await ref.read(streakProvider.future);
    if (!mounted) return;
    setState(() {
      _celebrating = true;
      _celebrateStreak = streak;
    });
  }

  Future<void> _onTooHard(int id, String title) async {
    final reason = await showTooHardSheet(context, title);
    if (reason == null) return;
    final micro = await ref.read(todayControllerProvider).tooHard(id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已为你变小：$micro')),
    );
  }

  Future<void> _onAdd() async {
    final result = await showAddTaskSheet(context);
    if (result == null) return;
    await ref
        .read(todayControllerProvider)
        .addTask(title: result.title, quadrant: result.quadrant);
  }

  Future<void> _prioritize() async {
    final view = ref.read(todayViewProvider).value;
    if (view == null) return;
    final titles =
        view.byQuadrant.values.expand((l) => l).map((t) => t.title).toList();
    if (titles.isEmpty) {
      _toast('今天还没有待办，先加一件吧');
      return;
    }
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isConfigured) {
      _toast('先到设置里填 AI key');
      return;
    }
    try {
      final r = await ai.prioritize(
        taskTitles: titles,
        todayEvents: view.events.map((e) => e.title).toList(),
      );
      if (mounted) _showSheet(PrioritizeResultView(result: r));
    } catch (e) {
      _toast('AI 出错：$e');
    }
  }

  Future<void> _reopenCompleted(TodayTask t) async {
    await ref.read(todayControllerProvider).reopen(t.id);
    if (mounted) _toast('已重新开启「${t.title}」');
  }

  Future<void> _deleteCompleted(TodayTask t) async {
    setState(() => _removing.add(t.id));
    await ref.read(todayControllerProvider).deleteTask(t.id);
    if (mounted) _toast('已删除「${t.title}」');
  }

  Future<void> _review() async {
    final db = ref.read(databaseProvider);
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isConfigured) {
      _toast('先到设置里填 AI key');
      return;
    }
    final today = ref.read(selectedDateProvider);
    final all = await db.taskDao.tasksForDate(today);
    final overdue = all
        .where((t) => t.status == TaskStatus.pending)
        .map((t) => '${t.title}（被推迟${t.rolloverCount}次，${t.quadrant.label}）')
        .toList();
    try {
      final items = await ai.review(overdue);
      if (mounted) _showSheet(ReviewResultView(items: items));
    } catch (e) {
      _toast('AI 出错：$e');
    }
  }

  void _showSheet(Widget child) => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => child,
      );

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final viewAsync = ref.watch(todayViewProvider);
    final streak = ref.watch(streakProvider).value ?? 0;
    final date = ref.watch(selectedDateProvider);

    return Stack(
      children: [
        Scaffold(
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _fabAction(
                  label: '整理今日',
                  icon: Icons.auto_awesome,
                  onTap: _prioritize),
              const SizedBox(height: 10),
              _fabAction(
                  label: '复盘未完成',
                  icon: Icons.history_edu,
                  onTap: _review),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'fab-add',
                backgroundColor: AppColors.ink,
                onPressed: _onAdd,
                child: const Icon(Icons.add, color: AppColors.paper),
              ),
            ],
          ),
          body: SafeArea(
            child: viewAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('出错了：$e')),
              data: (view) {
                return Column(
                  children: [
                    // 固定顶部：日期 + 连续天数/今日完成，不随下方列表滚动。
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        children: [
                          _header(context, date),
                          const SizedBox(height: 18),
                          StatsHeader(
                              streak: streak,
                              done: view.doneCount,
                              total: view.totalCount),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                    Expanded(child: _scrollBody(view)),
                  ],
                );
              },
            ),
          ),
        ),
        if (_celebrating)
          CelebrationOverlay(
            streak: _celebrateStreak,
            onDismiss: () => setState(() => _celebrating = false),
          ),
      ],
    );
  }

  List<Quadrant> _orderedQuadrants() =>
      [...Quadrant.values]..sort((a, b) => a.priority - b.priority);

  String _titleOf(TodayView view, int id) {
    for (final list in view.byQuadrant.values) {
      for (final t in list) {
        if (t.id == id) return t.title;
      }
    }
    return '';
  }

  Widget _header(BuildContext context, DateTime date) {
    final df = DateFormat('M月d日 · EEEE', 'zh');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(df.format(date),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.ink40)),
            const SizedBox(height: 3),
            Text('今天', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: AppColors.ink60),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // 下方可滚动区：日程 + 四象限任务 + 已完成（分页懒加载）。AI 操作移到浮动按钮。
  Widget _scrollBody(TodayView view) {
    final completed =
        view.completed.where((t) => !_removing.contains(t.id)).toList();
    _completedTotal = completed.length;
    final visible =
        completed.length < _completedLimit ? completed.length : _completedLimit;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ScheduleSection(events: view.events),
              for (final q in _orderedQuadrants())
                QuadrantSection(
                  quadrant: q,
                  tasks: view.byQuadrant[q] ?? const [],
                  microIds: const {},
                  onDone: _onDone,
                  onTooHard: (id) => _onTooHard(id, _titleOf(view, id)),
                ),
            ]),
          ),
        ),
        if (completed.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => i == 0
                    ? _completedHeader(completed.length)
                    : _completedRow(completed[i - 1]),
                childCount: visible + 1,
              ),
            ),
          ),
        if (completed.isNotEmpty && visible < completed.length)
          SliverToBoxAdapter(
            child: _loadMoreFooter(completed.length - visible),
          ),
        if (view.totalCount == 0)
          SliverFillRemaining(hasScrollBody: false, child: _emptyHint()),
        // 给浮动按钮列留出底部空间，避免遮住最后一条。
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Widget _completedHeader(int count) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.ink20),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('已完成 · $count',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.ink60)),
                const Text('点一下重开 · 右滑删除',
                    style: TextStyle(fontSize: 11, color: AppColors.ink40)),
              ],
            ),
          ],
        ),
      );

  Widget _completedRow(TodayTask t) => Dismissible(
        key: ValueKey('done-${t.id}'),
        direction: DismissDirection.startToEnd, // 右滑删除
        onDismissed: (_) => _deleteCompleted(t),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.q1.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 20, color: AppColors.q1),
              SizedBox(width: 6),
              Text('删除',
                  style: TextStyle(
                      color: AppColors.q1, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        child: InkWell(
          onTap: () => _reopenCompleted(t),
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: 0.55,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: AppColors.leaf, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            decoration: TextDecoration.lineThrough)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.replay, size: 16, color: AppColors.ink40),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _loadMoreFooter(int remaining) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: () => setState(() => _completedLimit += _completedPage),
            child: Text('显示更多已完成（还有 $remaining 项）',
                style: const TextStyle(color: AppColors.ink60)),
          ),
        ),
      );

  Widget _emptyHint() => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Text('今天还没有任务。\n点右下角 + 加一件，或在设置里导入飞书。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink40, height: 1.6)),
        ),
      );

  // 与 + 同处的浮动操作按钮（胶囊样式），点按触发 AI 整理 / 复盘。
  Widget _fabAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Material(
        color: AppColors.card,
        elevation: 2,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.ink20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: AppColors.ink),
                const SizedBox(width: 7),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink)),
              ],
            ),
          ),
        ),
      );
}
