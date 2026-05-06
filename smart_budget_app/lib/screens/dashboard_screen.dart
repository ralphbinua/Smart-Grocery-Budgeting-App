// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/ai_suggestion_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    double progress = cart.budgetLimit > 0 ? (cart.totalSpent / cart.budgetLimit) : 0;

    // NO SCAFFOLD HERE - JUST THE BODY
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text("Remaining Balance"),
                  Text(
                    "₱${cart.remaining.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: cart.remaining < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(10),
                    color: progress > 0.9 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Limit: ₱${cart.budgetLimit.toStringAsFixed(2)}"),
                      Text("Spent: ₱${cart.totalSpent.toStringAsFixed(2)}"),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Live Shopping Cart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                      ),
                      title: Text(item.name),
                      trailing: Text("₱${item.price.toStringAsFixed(2)}"),
                    ),
                    if (item.alternative != null)
                      AISuggestionCard(original: {'name': item.name, 'price': item.price}, alternative: item.alternative!),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          // Simulate Scan Button moved inside the body
          ElevatedButton.icon(
            onPressed: () => cart.addItemWithAI("Milk 1L", 95.0, {"name": "Store Milk", "price": 80.0}),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text("Simulate Scan"),
          ),
        ],
      ),
    );
  }
}