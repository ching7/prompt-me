import 'package:flutter/material.dart';
import '../../../domain/ai/ai_models.dart';
import '../../../theme/app_colors.dart';

class PrioritizeResultView extends StatelessWidget {
  const PrioritizeResultView({super.key, required this.result});
  final PrioritizeResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI 整理今日',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('今天先做：${result.todayFocus.join('、')}',
              style: const TextStyle(color: AppColors.q1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...result.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${s.taskTitle} → ${s.quadrant.label}（${s.reason}）'),
              )),
        ],
      ),
    );
  }
}

class ReviewResultView extends StatelessWidget {
  const ReviewResultView({super.key, required this.items});
  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI 复盘未完成',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('暂无未完成任务，或数据还不够。',
                style: TextStyle(color: AppColors.ink60)),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i.taskTitle}（${i.foggFactor}）',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${i.diagnosis} → ${i.suggestion}',
                        style: const TextStyle(color: AppColors.ink60)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
