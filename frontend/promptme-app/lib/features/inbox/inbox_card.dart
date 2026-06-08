import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 收件箱单条卡：领域色标 + 标题 + meta（领域/未分类 · 来源 · 时间）。
class InboxCard extends StatelessWidget {
  const InboxCard({
    super.key,
    required this.title,
    required this.domain,
    required this.subtitle,
  });

  final String title;
  final String? domain;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink20),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.domainColor(domain)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (hasDomain) ...[
                        CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.domainColor(domain)),
                        const SizedBox(width: 4),
                        Text(domain!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.domainColor(domain))),
                      ] else
                        Text('未分类',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink40)),
                      const SizedBox(width: 9),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.ink40)),
                    ]),
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
