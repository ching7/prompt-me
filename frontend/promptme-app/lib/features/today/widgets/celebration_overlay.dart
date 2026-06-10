import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.streak,
    required this.onDismiss,
    this.pointsDelta,
  });
  final int streak;
  final VoidCallback onDismiss;
  final int? pointsDelta;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _confetti.play();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper.withValues(alpha: 0.98),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 22,
              maxBlastForce: 18,
              colors: const [
                AppColors.q1,
                AppColors.q2,
                AppColors.q3,
                AppColors.leaf,
                AppColors.pop,
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                    color: AppColors.ink, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.leaf, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('连续天数 +1',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.ink40)),
              const SizedBox(height: 6),
              Text('🔥 ${widget.streak}',
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w700, height: 1)),
              const SizedBox(height: 18),
              const Text('做到了。这就是积累。',
                  style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500)),
              if (widget.pointsDelta != null) ...[
                const SizedBox(height: 10),
                Text('+${widget.pointsDelta} 分',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pop)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
