import 'package:flutter/material.dart';

/// 统一小标签 chip：圆角/内距/字号一致。
/// - **只读(提示类)**：浅底 + 描边 + 彩字（便签/降级/诊断/来源）。
/// - **可操作**(传了 onTap)：**实底 + 白字 + ▶ 图标** → 一眼看出"能点"。
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.text,
    required this.color,
    this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actionable = onTap != null;
    final box = Container(
      padding: EdgeInsets.fromLTRB(8, 4, actionable ? 5 : 8, 4),
      decoration: BoxDecoration(
        color: actionable ? color : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: actionable ? color : color.withValues(alpha: .30)),
      ),
      child: actionable
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(width: 1),
                const Icon(Icons.play_arrow_rounded,
                    size: 14, color: Colors.white),
              ],
            )
          : Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
    );
    if (!actionable) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: box,
    );
  }
}
