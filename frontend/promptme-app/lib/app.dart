import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/today/today_screen.dart';

class PromptMeApp extends StatelessWidget {
  const PromptMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const TodayScreen(),
    );
  }
}
