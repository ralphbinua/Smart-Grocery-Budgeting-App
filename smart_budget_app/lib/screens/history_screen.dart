import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for past trips
    final List<Map<String, dynamic>> pastTrips = [
      {"date": "May 05, 2026", "total": 4250.00, "saved": 320.00},
      {"date": "April 28, 2026", "total": 1200.50, "saved": 45.00},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Purchase History")),
      body: ListView.builder(
        itemCount: pastTrips.length,
        itemBuilder: (context, index) {
          final trip = pastTrips[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              title: Text("Trip on ${trip['date']}"),
              subtitle: Text("Saved ₱${trip['saved']} via AI"),
              trailing: Text("₱${trip['total']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                // Future: Show specific items from this receipt
              },
            ),
          );
        },
      ),
    );
  }
}