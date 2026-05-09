import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AISuggestionCard extends StatelessWidget {
  final Map<String, dynamic> original;
  final Map<String, dynamic> alternative;

  const AISuggestionCard({super.key, required this.original, required this.alternative});

  @override
  Widget build(BuildContext context) {
    final double savings = (original['price'] as num).toDouble() - (alternative['price'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.08), AppColors.primary.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.purpleGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI COST OPTIMIZATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accent, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                    children: [
                      const TextSpan(text: 'Try ', style: TextStyle(color: AppColors.textSecondary)),
                      TextSpan(text: alternative['name'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' instead', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text('Save ₱${savings.toStringAsFixed(2)} per item', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text('₱${(alternative['price'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}