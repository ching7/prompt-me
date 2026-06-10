import 'package:flutter/material.dart';
import '../../domain/domains.dart';
import '../../theme/app_colors.dart';

/// 手记表单（取自原型 Flow 01「捕获 · 想到就走」）：
/// 提示语 + 墨框输入 + 领域标签（默认选中第一个、必选）→ onCapture(text, domain)。
class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key, required this.onCapture});
  final void Function(String text, String? domain) onCapture;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _ctrl = TextEditingController();
  String _domain = kDefaultDomains.first; // 默认选中，标签必选、不可空

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onCapture(text, _domain);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.ink20,
                  borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('记一笔',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('想到什么先记下来 · 之后再整理，别打断手头的活',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink60)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            cursorColor: AppColors.pop,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '研究 MCP 协议…',
              hintStyle: const TextStyle(
                  color: AppColors.ink40, fontWeight: FontWeight.w500),
              filled: true,
              fillColor: AppColors.paper,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Text('标签',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink40)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final d in kDefaultDomains)
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: _tagChip(d),
                      ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('记完即整理 · +2 分',
                  style: TextStyle(fontSize: 11, color: AppColors.ink40)),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.leaf,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  textStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                child: const Text('记一笔'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 领域标签胶囊（原型 .ctseg）：纸2 底 + 色点；选中 = 领域色描边 + 同色字。
  Widget _tagChip(String d) {
    final on = _domain == d;
    final c = AppColors.domainColor(d);
    return GestureDetector(
      onTap: () => setState(() => _domain = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? c.withValues(alpha: 0.07) : AppColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: on ? c : AppColors.ink20, width: on ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: 5),
          Text(d,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: on ? c : AppColors.ink60)),
        ]),
      ),
    );
  }
}
