import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 统一的 AI 动作按钮：胶囊样式，与 StatsChip（积分栏）同尺寸/同观感。
/// 待办「AI 整理」、复盘「AI 复盘」共用，保证大小样式一致。
class AiButton extends StatelessWidget {
  const AiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.ink20)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: loading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.ink60),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink60)),
            ],
          ),
        ),
      ),
    );
  }
}
