import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    final downgraded = downgradeLevel > 0 && !done;
    return Container(
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
                          if (downgraded) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('🌱 微习惯 · 已降级 $downgradeLevel 次',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.leaf)),
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (!done && diagnosisLabel != null) ...[
                            Row(children: [
                              Text('🩺 $diagnosisLabel',
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.q1)),
                            ]),
                            const SizedBox(height: 5),
                          ],
                          Text(title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: done ? AppColors.ink40 : AppColors.ink,
                              )),
                          if (downgraded && (originTitle?.trim().isNotEmpty ?? false)) ...[
                            const SizedBox(height: 3),
                            Text('来自原任务：$originTitle',
                                style: TextStyle(
                                    fontSize: 10.5, color: AppColors.ink40)),
                          ],
                          const SizedBox(height: 6),
                          Row(children: [
                            if (hasDomain) ...[
                              CircleAvatar(
                                  radius: 3,
                                  backgroundColor:
                                      AppColors.domainColor(domain)),
                              const SizedBox(width: 4),
                              Text(domain!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.domainColor(domain))),
                            ] else
                              Text('未分类',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.ink40)),
                            if (overdue) ...[
                              const SizedBox(width: 9),
                              Text('⏰ 已推迟 $rolloverCount 次',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.q1)),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    if (!done) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        key: const ValueKey('todo-focus'),
                        onTap: onFocus,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.q1Tint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              '🍅 $tomatoDone${tomatoEst != null ? '/$tomatoEst' : ''}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.q1)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
