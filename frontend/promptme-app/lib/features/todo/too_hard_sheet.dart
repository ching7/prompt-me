import 'package:flutter/material.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';

/// 压缩版「太难了」：一句话标题 + 一行 P/A/M chip → onReason。
class TooHardSheet extends StatelessWidget {
  const TooHardSheet(
      {super.key, required this.taskTitle, required this.onReason});
  final String taskTitle;
  final void Function(FailureReason) onReason;

  static const _reasons = [
    (FailureReason.forgot, '🌫️', '忘记了', 'P · 提示'),
    (FailureReason.tired, '🪫', '太累了', 'A · 精力'),
    (FailureReason.noMotivation, '🫥', '没动力', 'M · 动机'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: '太难了？'),
              TextSpan(
                  text: '我帮你变小',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: AppColors.q3)),
            ]),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text('卡在哪——选一下，把「$taskTitle」降到 2 分钟：',
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink60)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final r in _reasons)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: _chip(r.$1, r.$2, r.$3, r.$4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(FailureReason reason, String ic, String label, String tag) {
    return InkWell(
      onTap: () => onReason(reason),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 13, 6, 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.ink20, width: 1.5),
        ),
        child: Column(
          children: [
            Text(ic, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(tag,
                style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink40)),
          ],
        ),
      ),
    );
  }
}
