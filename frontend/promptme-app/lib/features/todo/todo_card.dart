import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tag_chip.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.title,
    required this.domain,
    required this.done,
    required this.overdue,
    required this.rolloverCount,
    this.downgradeLevel = 0,
    this.originTitle,
    this.diagnosisLabel,
    required this.tomatoDone,
    required this.tomatoEst,
    required this.onToggle,
    required this.onFocus,
    this.onTap,
  });

  final String title;
  final String? domain;
  final bool done;
  final bool overdue;
  final int rolloverCount;
  final int downgradeLevel;
  final String? originTitle;

  /// MAP 诊断：「总卡在『…』」；无清晰模式时为 null。
  final String? diagnosisLabel;
  final int tomatoDone;
  final int? tomatoEst;
  final VoidCallback onToggle;
  final VoidCallback onFocus;

  /// 点卡身（非勾选框/非番茄）→ 看详情/编辑。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    final downgraded = downgradeLevel > 0 && !done;
    final hasDiag = !done && diagnosisLabel != null;
    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: downgraded ? AppColors.leaf.withValues(alpha: .06) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: downgraded
                ? AppColors.leaf.withValues(alpha: .45)
                : overdue
                    ? AppColors.q1.withValues(alpha: .38)
                    : AppColors.ink20),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                width: 4,
                color: downgraded
                    ? AppColors.leaf
                    : AppColors.domainColor(domain)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 13, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      key: const ValueKey('todo-toggle'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                          done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: done ? AppColors.leaf : AppColors.ink40,
                          size: 22),
                      onPressed: onToggle,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 主：任务内容（标题）在上
                          Text(title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: done ? AppColors.ink40 : AppColors.ink,
                              )),
                          if (downgraded &&
                              (originTitle?.trim().isNotEmpty ?? false)) ...[
                            const SizedBox(height: 3),
                            Text('来自原任务：$originTitle',
                                style: TextStyle(
                                    fontSize: 10.5, color: AppColors.ink40)),
                          ],
                          if (overdue) ...[
                            const SizedBox(height: 3),
                            Text('⏰ 已推迟 $rolloverCount 次',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.q1)),
                          ],
                          const SizedBox(height: 8),
                          // 次：标签/按钮在下。左=便签/降级/ai分析(提示)，右=🍅番茄(可操作)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TagChip(
                                      text:
                                          hasDomain ? '🏷 ${domain!}' : '🏷 未分类',
                                      color: hasDomain
                                          ? AppColors.domainColor(domain)
                                          : AppColors.ink40,
                                    ),
                                    if (downgraded) ...[
                                      const SizedBox(width: 6),
                                      TagChip(
                                        text: '🌱 降级 $downgradeLevel 次',
                                        color: AppColors.leaf,
                                      ),
                                    ],
                                    if (hasDiag) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: TagChip(
                                          text: '🩺 $diagnosisLabel',
                                          color: AppColors.pop,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!done) ...[
                                const SizedBox(width: 8),
                                TagChip(
                                  key: const ValueKey('todo-focus'),
                                  text:
                                      '🍅 $tomatoDone${tomatoEst != null ? '/$tomatoEst' : ''}',
                                  color: AppColors.q1,
                                  onTap: onFocus,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
