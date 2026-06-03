import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

/// 以 modal bottom sheet 形式展示，用户选原因后返回该 [FailureReason]。
Future<FailureReason?> showTooHardSheet(BuildContext context, String taskTitle) {
  return showModalBottomSheet<FailureReason>(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _TooHardSheet(taskTitle: taskTitle),
  );
}

class _TooHardSheet extends StatelessWidget {
  const _TooHardSheet({required this.taskTitle});
  final String taskTitle;

  static const _reasons = [
    (FailureReason.forgot, '🌫️', 'P · 提示没接住'),
    (FailureReason.tired, '🪫', 'A · 能力/精力不够'),
    (FailureReason.noMotivation, '🫥', 'M · 动机不足'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.ink20,
                    borderRadius: BorderRadius.circular(5))),
          ),
          const SizedBox(height: 18),
          const Text('这件事太难了？没关系，我把它变小。',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 8),
          Text('选一个原因——我会据此把「$taskTitle」降到 2 分钟。',
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink60)),
          const SizedBox(height: 18),
          ..._reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, r.$1),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.ink20, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(r.$2, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text(r.$3,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink40)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          const Center(
            child: Text('降低门槛不是放弃。动机推不动、累也消不掉，但「变小」永远做得到。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.ink40)),
          ),
        ],
      ),
    );
  }
}
