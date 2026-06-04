class GroceryInputItem {
  final String id;
  String name;
  int quantity;
  double? estimatedPrice; // optional user-provided price hint

  GroceryInputItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.estimatedPrice,
  });
}
