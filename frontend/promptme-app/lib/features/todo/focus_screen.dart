import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/score/score_calculator.dart';
import '../../state/integration_providers.dart';
import '../../state/todo_controller.dart';
import '../../theme/app_colors.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.tomatoEst,
    this.workSeconds = 25 * 60,
  });
  final int taskId;
  final String taskTitle;
  final int? tomatoEst;
  final int workSeconds;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  late int _remaining = widget.workSeconds;
  late int? _est = widget.tomatoEst;
  Timer? _timer;
  bool _paused = false;
  bool _completed = false;
  bool _aiEstimating = false;

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

  /// 放弃：记一条 tomatoAbort（带已专注秒数 → 喂 MAP 二次诊断），再退出。
  Future<void> _abort() async {
    _timer?.cancel();
    final focusedSec = widget.workSeconds - _remaining; // 已专注时长
    await ref
        .read(todoControllerProvider)
        .abortTomato(widget.taskId, focusedSec: focusedSec);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _setEst(int n) async {
    setState(() => _est = n);
    await ref.read(todoControllerProvider).setTomatoEst(widget.taskId, n);
  }

  /// AI 估番茄（仅 AI 开时入口可见）：调模型 → 落库 → 回填选中。失败兜底已在 client 内。
  Future<void> _aiEstimate() async {
    setState(() => _aiEstimating = true);
    final n = await ref
        .read(todoControllerProvider)
        .estimateTomato(widget.taskId, widget.taskTitle);
    if (mounted) {
      setState(() {
        _aiEstimating = false;
        if (n != null) _est = n;
      });
    }
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
        const SizedBox(height: 22),
        _estimateRow(),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _abort,
              child: const Text('放弃'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => setState(() => _paused = !_paused),
              child: Text(_paused ? '继续' : '暂停'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton(
          key: const ValueKey('focus-complete'),
          onPressed: _complete, // 提前完成：直接 +1 🍅，不必等满 25 分
          child: Text('提前完成 +1 🍅',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.leaf)),
        ),
        const SizedBox(height: 4),
        Text('到点自动 +1 🍅 · 之后短休 5 分',
            style: TextStyle(fontSize: 11, color: AppColors.ink40)),
      ],
    );
  }

  Widget _estimateRow() {
    final aiActive = ref.watch(aiClientProvider).config.isActive;
    return Column(
      children: [
        Text(_est == null ? '预估几个 🍅？' : '预估 $_est 🍅',
            style: const TextStyle(fontSize: 12, color: AppColors.ink40)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var n = 1; n <= 4; n++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _estChip(n),
              ),
          ],
        ),
        // AI 估入口：仅 AI 开时出现；关 AI = 只能手选（保留现状）。
        if (aiActive) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('focus-ai-est'),
            onPressed: _aiEstimating ? null : _aiEstimate,
            icon: _aiEstimating
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('✨', style: TextStyle(fontSize: 13)),
            label: Text(_aiEstimating ? '估算中…' : 'AI 估🍅',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.q3)),
          ),
        ],
      ],
    );
  }

  Widget _estChip(int n) {
    final selected = _est == n;
    return GestureDetector(
      key: ValueKey('focus-est-$n'),
      onTap: () => _setEst(n),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.q1 : AppColors.paper,
          border: Border.all(
              color: selected ? AppColors.q1 : AppColors.ink20, width: 1.5),
        ),
        child: Center(
          child: Text('$n',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink60)),
        ),
      ),
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
        const SizedBox(height: 6),
        Text('+${ScoreCalculator.tomatoPoints} 分',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.pop)),
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
