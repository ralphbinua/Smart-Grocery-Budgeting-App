import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class BudgetRing extends StatelessWidget {
  final double progress;
  final bool isOver;
  final bool isNear;

  const BudgetRing({
    super.key,
    required this.progress,
    required this.isOver,
    required this.isNear,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOver ? AppColors.danger : isNear ? AppColors.warning : AppColors.primary;
    final percentage = (progress * 100).toStringAsFixed(0);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _RingPainter(progress: progress, color: color),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$percentage%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              const Text('used', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );

    // Glow effect
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
