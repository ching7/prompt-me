import 'package:flutter/material.dart';
import '../../../domain/enums.dart';
import '../../../theme/app_colors.dart';

class AddTaskResult {
  final String title;
  final Quadrant quadrant;
  AddTaskResult(this.title, this.quadrant);
}

Future<AddTaskResult?> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet<AddTaskResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddTaskSheet(),
  );
}

/// 外层只负责「随键盘 inset 变化的底部 padding」。内容用 const 子组件，
/// 键盘升起时 Flutter 对 identical 的 const child 跳过 rebuild，只重排，
/// 避免每帧重建整张表单导致的掉帧。
class _AddTaskSheet extends StatelessWidget {
  const _AddTaskSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const _AddTaskForm(),
    );
  }
}

class _AddTaskForm extends StatefulWidget {
  const _AddTaskForm();
  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Quadrant _q = Quadrant.importantUrgent;

  @override
  void initState() {
    super.initState();
    // 等弹窗滑入动画落定（~220ms）后再聚焦弹键盘，避免两段动画叠加掉帧。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('加一件今天要做的事',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            decoration: InputDecoration(
              hintText: '例如：完成项目周报',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.ink20)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: Quadrant.values
                .map((q) => ChoiceChip(
                      label: Text(q.label),
                      selected: _q == q,
                      onSelected: (_) => setState(() => _q = q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: () {
                final text = _ctrl.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, AddTaskResult(text, _q));
              },
              child: const Text('加入今日'),
            ),
          ),
        ],
      ),
    );
  }
}
