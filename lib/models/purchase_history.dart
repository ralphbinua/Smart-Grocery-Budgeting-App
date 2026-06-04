class PurchaseHistory {
  final String id;
  final String date;
  final List<HistoryItem> items;
  final double totalSpent;
  final double budgetLimit;
  final double totalSaved;
  final String storeName;

  PurchaseHistory({
    required this.id,
    required this.date,
    required this.items,
    required this.totalSpent,
    required this.budgetLimit,
    required this.totalSaved,
    this.storeName = 'Grocery Store',
  });

  double get budgetUsedPercent =>
      budgetLimit > 0 ? (totalSpent / budgetLimit) * 100 : 0;
}

class HistoryItem {
  final String name;
  final double price;
  final int quantity;
  final String category;

  HistoryItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
  });

  double get total => price * quantity;
}
