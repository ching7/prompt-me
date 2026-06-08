import 'package:flutter/material.dart';
import '../../domain/domains.dart';
import '../../theme/app_colors.dart';

/// 手记表单：文本 + 可选领域标签 → onCapture(text, domain)。domain 为 null = 未分类。
class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key, required this.onCapture});
  final void Function(String text, String? domain) onCapture;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _ctrl = TextEditingController();
  String? _domain;

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
          20, 18, 20, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('记一笔',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '想到什么先记下来…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final d in kDefaultDomains)
                ChoiceChip(
                  label: Text(d),
                  selected: _domain == d,
                  avatar: CircleAvatar(
                      radius: 5, backgroundColor: AppColors.domainColor(d)),
                  onSelected: (sel) =>
                      setState(() => _domain = sel ? d : null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _submit, child: const Text('记一笔')),
          ),
        ],
      ),
    );
  }
}
