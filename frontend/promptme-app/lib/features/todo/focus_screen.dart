import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.workSeconds = 25 * 60,
  });
  final int taskId;
  final String taskTitle;
  final int workSeconds;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  late int _remaining = widget.workSeconds;
  Timer? _timer;
  bool _paused = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _completed) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _complete();
    });
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await ref.read(todoControllerProvider).completeTomato(widget.taskId);
    if (mounted) setState(() => _completed = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _mmss {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: _completed ? _done() : _running(),
        ),
      ),
    );
  }

  Widget _running() {
    final progress =
        widget.workSeconds == 0 ? 0.0 : _remaining / widget.workSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.ink20,
                  valueColor: const AlwaysStoppedAnimation(AppColors.q1),
                ),
              ),
              Text(_mmss,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(widget.taskTitle,
            style:
                const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('放弃'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => setState(() => _paused = !_paused),
              child: Text(_paused ? '继续' : '暂停'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('完成 +1 🍅 · 之后短休 5 分',
            style: TextStyle(fontSize: 11, color: AppColors.ink40)),
      ],
    );
  }

  Widget _done() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍅', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('番茄完成 +1',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('该短休 5 分了 · ${widget.taskTitle}',
            style: TextStyle(fontSize: 13, color: AppColors.ink60)),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ],
    );
  }
}
