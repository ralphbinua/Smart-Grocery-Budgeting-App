import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanAnimation extends StatefulWidget {
  const ScanAnimation({super.key});

  @override
  State<ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<ScanAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Barcode lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (i) => Container(
              width: i % 3 == 0 ? 4 : 2,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
          // Scanner line
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => Positioned(
              top: 10 + (_animation.value * 80),
              left: 10,
              right: 10,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                    Colors.transparent,
                  ]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
