import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const SmartGroceryApp(),
    ),
  );
}

// 1. ADDED THIS CLASS: It must be a StatefulWidget to hold the state below
class SmartGroceryApp extends StatefulWidget {
  const SmartGroceryApp({super.key});

  @override
  State<SmartGroceryApp> createState() => _SmartGroceryAppState();
}

class _SmartGroceryAppState extends State<SmartGroceryApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
  ];

  void _showBudgetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text("Set Shopping Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true, // Keypad opens automatically
          decoration: const InputDecoration(
            hintText: "Enter amount (₱)",
            prefixText: "₱ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // We use 'context' from the build method to access the Provider
              final budget = double.tryParse(controller.text) ?? 0;
              Provider.of<CartProvider>(
                context,
                listen: false,
              ).setBudget(budget);
              Navigator.pop(innerContext);

              // Optional: Show a confirmation toast
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Budget set to ₱$budget")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Use a Builder here so the 'context' has access to the Theme and Providers
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Smart Grocery"),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                onPressed: () => _showBudgetDialog(context),
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
