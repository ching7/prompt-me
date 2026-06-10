import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 统一的「+」浮动按钮：墨色圆形 + 纸色加号，取自高保真原型（非 Material 默认色）。
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.paper,
      elevation: 6,
      highlightElevation: 6,
      focusElevation: 6,
      hoverElevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 24),
    );
  }
}
