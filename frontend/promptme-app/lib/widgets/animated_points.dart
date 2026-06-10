import 'package:flutter/material.dart';

/// 总积分文本，分值上升时弹一下（正反馈「跳动」）。
class AnimatedPoints extends StatefulWidget {
  const AnimatedPoints({super.key, required this.points, this.style});
  final int points;
  final TextStyle? style;

  @override
  State<AnimatedPoints> createState() => _AnimatedPointsState();
}

class _AnimatedPointsState extends State<AnimatedPoints>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35),
    TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65),
  ]).animate(_c);

  @override
  void didUpdateWidget(AnimatedPoints old) {
    super.didUpdateWidget(old);
    if (widget.points > old.points) _c.forward(from: 0); // 仅上升时弹
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Text('★${widget.points}', style: widget.style),
      );
}
