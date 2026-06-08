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
    required this.onToggle,
  });

  final String title;
  final String? domain;
  final bool done;
  final bool overdue;
  final int rolloverCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: overdue ? AppColors.q1.withValues(alpha: .38) : AppColors.ink20),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.domainColor(domain)),
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
                          Text(title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: done ? AppColors.ink40 : AppColors.ink,
                              )),
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
