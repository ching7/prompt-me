import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 衬线标题样式：打包的宋体子集（family 'Songti'）+ 系统衬线兜底。
/// 各屏大标题 / 弹窗标题用，斜体走 Flutter 合成倾斜（宋体无真斜体）。
class AppText {
  static const _serif = 'Songti';
  static const _fallback = ['Songti SC', 'STSong', 'serif'];

  static TextStyle title(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
    bool italic = true,
  }) =>
      TextStyle(
        fontFamily: _serif,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.12,
        letterSpacing: -0.2,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );
}
