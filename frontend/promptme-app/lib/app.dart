import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

class PromptMeApp extends StatelessWidget {
  const PromptMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PromptMe', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('记录每一次行动', style: TextStyle(color: AppColors.ink60)),
            ],
          ),
        ),
      ),
    );
  }
}
