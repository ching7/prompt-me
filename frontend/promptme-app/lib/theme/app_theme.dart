import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const _zhFallback = ['PingFang SC', 'Noto Sans SC'];

  static ThemeData light() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final body = GoogleFonts.hankenGroteskTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamilyFallback: _zhFallback,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.q1,
        surface: AppColors.card,
      ),
      textTheme: body.copyWith(
        // Fraunces 用于大字/数字（中文回退继承自 body 的 .apply）
        displayLarge: GoogleFonts.fraunces(
          textStyle: body.displayLarge,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.fraunces(
          textStyle: body.headlineMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
