import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tag_chip.dart';

/// 收件箱单条卡：领域色标 + 标题 + meta（领域/未分类 · 来源 · 时间）。
class InboxCard extends StatelessWidget {
  const InboxCard({
    super.key,
    required this.title,
    required this.domain,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String? domain;
  final String subtitle;

  /// 点卡身 → 看详情/编辑。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasDomain = domain != null && domain!.trim().isNotEmpty;
    final card = Container(
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
                    // 主：任务内容（标题）在上
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // 次：标签 + 来源在下，与待办卡同款 TagChip
                    Row(children: [
                      Flexible(
                        child: TagChip(
                          text: hasDomain ? '🏷 ${domain!}' : '🏷 未分类',
                          color: hasDomain
                              ? AppColors.domainColor(domain)
                              : AppColors.ink40,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TagChip(text: subtitle, color: AppColors.ink40),
                    ]),
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
