import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;

  const CategoryChip({super.key, required this.label});

  Color _color() {
    const colors = {
      'Dairy': AppColors.info,
      'Bakery': AppColors.warning,
      'Beverages': AppColors.accentLight,
      'Snacks': AppColors.accent,
      'Meat': AppColors.danger,
      'Canned Goods': Color(0xFF10B981),
      'Instant Food': Color(0xFFF97316),
    };
    return colors[label] ?? AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
