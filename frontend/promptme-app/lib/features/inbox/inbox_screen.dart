import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/domains.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../state/inbox_controller.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../widgets/animated_points.dart';
import '../../widgets/app_fab.dart';
import 'capture_sheet.dart';
import 'inbox_card.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  // 仅领域过滤可真做；按时间「优先今日」需捕获时间戳（Task 表暂无 capturedAt），后置。
  String? _domainFilter;

  List<Task> _filter(List<Task> items) {
    if (_domainFilter == null) return items;
    return items.where((t) => t.domain == _domainFilter).toList();
  }

  void _openCapture() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.paper,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: CaptureSheet(
          onCapture: (text, domain) {
            ref
                .read(inboxControllerProvider)
                .capture(text: text, domain: domain);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxProvider);
    final points = ref.watch(pointsProvider).value ?? 0;
    return Scaffold(
      floatingActionButton: AppFab(onPressed: _openCapture),
      body: SafeArea(
        child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
        data: (all) {
          final items = _filter(all);
          return Column(
            children: [
              // 固定顶栏：标题 + 标签过滤
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text('收件箱',
                          style: AppText.title(25, weight: FontWeight.w700)),
                      const SizedBox(width: 9),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${all.length} 条待整理',
                            style: const TextStyle(
                                color: AppColors.ink40,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      // ★ 总积分：捕获 +2 即时可见
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.ink20),
                        ),
                        child: AnimatedPoints(
                            points: points,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.pop)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _filterBar(),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _resync,
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  children: [
                    if (items.isNotEmpty)
                      _bulkAddButton(items.map((t) => t.id).toList()),
                    const SizedBox(height: 6),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('收件箱空了 · 想到什么按 + 记一笔',
                              style: TextStyle(color: AppColors.ink40)),
                        ),
                      )
                    else ...[
                      _swipeHint(),
                      for (final t in items) _dismissibleCard(t),
                    ],
                  ],
                ),
                ),
              ),
            ],
          );
        },
      )),
    );
  }

  Widget _filterBar() {
    return Row(children: [
      const Text('标签',
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink40)),
      const SizedBox(width: 8),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in kDefaultDomains)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: _domChip(d),
                ),
            ],
          ),
        ),
      ),
    ]);
  }

  /// 领域过滤胶囊：纸2 底 + 色点 + 名（取自原型 .inbf-tag）；选中=墨底白字。
  Widget _domChip(String d) {
    final on = _domainFilter == d;
    return GestureDetector(
      onTap: () => setState(() => _domainFilter = on ? null : d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? AppColors.ink : AppColors.ink20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: AppColors.domainColor(d)),
          ),
          const SizedBox(width: 5),
          Text(d,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : AppColors.ink60)),
        ]),
      ),
    );
  }

  Widget _bulkAddButton(List<int> ids) {
    return InkWell(
      onTap: () => ref.read(inboxControllerProvider).addAllToToday(ids),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.leaf.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.leaf.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('✓ 全部加入今日',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.leaf,
                    fontSize: 13)),
            Text('当前 ${ids.length} 条 →',
                style: TextStyle(color: AppColors.ink40, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dismissibleCard(Task t) {
    return Dismissible(
      key: ValueKey(t.id),
      background: Container(
        alignment: Alignment.centerLeft,
        color: AppColors.q1, // 左滑→删除
        padding: const EdgeInsets.only(left: 20),
        child: const Text('删除', style: TextStyle(color: Colors.white)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        color: AppColors.leaf, // 右滑→加入今日
        padding: const EdgeInsets.only(right: 20),
        child: const Text('加入今日', style: TextStyle(color: Colors.white)),
      ),
      confirmDismiss: (dir) async {
        final ctl = ref.read(inboxControllerProvider);
        if (dir == DismissDirection.endToStart) {
          await ctl.addToToday(t.id);
        } else {
          await ctl.delete(t.id);
        }
        return true;
      },
      child: InboxCard(
        title: t.title,
        domain: t.domain,
        subtitle: t.source == TaskSource.capture ? '💻 捕获' : '✍️ 手记',
        onTap: () => _openDetail(t),
      ),
    );
  }

  /// 下拉刷新 = 强制 ntfy 续传兜底（列表本身响应式，这里主要催同步补漏）。
  Future<void> _resync() async {
    await ref.read(ntfySyncServiceProvider).resync();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// 滑动手势提示（可发现性）。
  Widget _swipeHint() => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👈 左滑',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.leaf)),
            Text(' 加入今日 · 点卡看详情 · 删除 ',
                style: TextStyle(fontSize: 10.5, color: AppColors.ink40)),
            Text('右滑 👉',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.q1)),
          ],
        ),
      );

  /// 点卡身 → 收件箱条目详情：编辑标题 + 删除 / 加入今日。
  void _openDetail(Task t) {
    final controller = TextEditingController(text: t.title);
    showDialog(
      context: context,
      builder: (dctx) => Dialog(
        backgroundColor: AppColors.paper,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('条目详情', style: AppText.title(20)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(fontSize: 14.5),
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                  '${t.domain ?? '未分类'} · ${t.source == TaskSource.capture ? '💻 捕获' : '✍️ 手记'}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.ink60)),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref.read(inboxControllerProvider).delete(t.id);
                      if (dctx.mounted) Navigator.of(dctx).pop();
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.q1),
                    child: const Text('删除'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final txt = controller.text.trim();
                      if (txt.isNotEmpty && txt != t.title) {
                        await ref
                            .read(inboxControllerProvider)
                            .editTitle(t.id, txt);
                      }
                      if (dctx.mounted) Navigator.of(dctx).pop();
                    },
                    child: const Text('保存'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () async {
                      final txt = controller.text.trim();
                      if (txt.isNotEmpty && txt != t.title) {
                        await ref
                            .read(inboxControllerProvider)
                            .editTitle(t.id, txt);
                      }
                      await ref.read(inboxControllerProvider).addToToday(t.id);
                      if (dctx.mounted) Navigator.of(dctx).pop();
                    },
                    child: const Text('加入今日'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
