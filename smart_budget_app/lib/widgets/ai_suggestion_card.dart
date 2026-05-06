import 'package:flutter/material.dart';

class AISuggestionCard extends StatelessWidget {
  final Map<String, dynamic> original;
  final Map<String, dynamic> alternative;

  const AISuggestionCard({super.key, required this.original, required this.alternative});

  @override
  Widget build(BuildContext context) {
    double savings = original['price'] - alternative['price'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI COST OPTIMIZATION",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                Text("Try ${alternative['name']} instead of ${original['name']}.",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text("Estimated Savings: ₱${savings.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}