import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/domains.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../state/inbox_controller.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        onCapture: (text, domain) {
          ref.read(inboxControllerProvider).capture(text: text, domain: domain);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openCapture,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
        data: (all) {
          final items = _filter(all);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              Row(children: [
                const Text('收件箱',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('${all.length} 条待整理',
                    style: TextStyle(color: AppColors.ink40, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              _filterBar(),
              const SizedBox(height: 8),
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
              else
                for (final t in items) _dismissibleCard(t),
            ],
          );
        },
      )),
    );
  }

  Widget _filterBar() {
    return Row(children: [
      Text('标签',
          style: TextStyle(
              fontSize: 11,
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
                  child: FilterChip(
                    label: Text(d),
                    selected: _domainFilter == d,
                    avatar: CircleAvatar(
                        radius: 5, backgroundColor: AppColors.domainColor(d)),
                    onSelected: (sel) =>
                        setState(() => _domainFilter = sel ? d : null),
                  ),
                ),
            ],
          ),
        ),
      ),
    ]);
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
      ),
    );
  }
}
