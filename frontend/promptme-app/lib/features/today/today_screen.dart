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

  Future<void> _prioritize(TodayView view) async {
    final titles =
        view.byQuadrant.values.expand((l) => l).map((t) => t.title).toList();
    if (titles.isEmpty) return;
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.ink,
            onPressed: _onAdd,
            child: const Icon(Icons.add, color: AppColors.paper),
          ),
          body: SafeArea(
            child: viewAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('出错了：$e')),
              data: (view) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _header(context, date),
                  const SizedBox(height: 18),
                  StatsHeader(
                      streak: streak,
                      done: view.doneCount,
                      total: view.totalCount),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _prioritize(view),
                          child: const Text('整理今日(AI)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _review,
                          child: const Text('复盘未完成(AI)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ScheduleSection(events: view.events),
                  for (final q in _orderedQuadrants())
                    QuadrantSection(
                      quadrant: q,
                      tasks: view.byQuadrant[q] ?? const [],
                      microIds: const {},
                      onDone: _onDone,
                      onTooHard: (id) => _onTooHard(id, _titleOf(view, id)),
                    ),
                  if (view.completed.isNotEmpty) _completed(view),
                  if (view.totalCount == 0) _emptyHint(),
                ],
              ),
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

  Widget _completed(TodayView view) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Divider(color: AppColors.ink20),
          ...view.completed.map((t) => Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.leaf, shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(t.title,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
              )),
        ],
      );

  Widget _emptyHint() => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Text('今天还没有任务。\n点右下角 + 加一件，或在设置里导入飞书。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink40, height: 1.6)),
        ),
      );
}
