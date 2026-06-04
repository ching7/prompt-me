import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/import/feishu_importer.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';

class FeishuImportSheet extends ConsumerStatefulWidget {
  const FeishuImportSheet({super.key});
  @override
  ConsumerState<FeishuImportSheet> createState() => _FeishuImportSheetState();
}

class _FeishuImportSheetState extends ConsumerState<FeishuImportSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final db = ref.read(databaseProvider);
    final date = ref.read(selectedDateProvider);
    final count = await FeishuImporter(db).import(_ctrl.text, targetDate: date);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已导入 $count 条今日任务')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 18, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('粘贴飞书文档（Markdown）',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('在飞书把今天的工作文档导出/复制为 Markdown，粘到这里。',
              style: TextStyle(fontSize: 13, color: AppColors.ink60)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '# 0603\n## 重要紧急\n- [ ] ...',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.ink20)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: _import,
              child: const Text('导入今日任务'),
            ),
          ),
        ],
      ),
    );
  }
}
