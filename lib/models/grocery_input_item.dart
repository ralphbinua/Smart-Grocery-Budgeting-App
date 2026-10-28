class GroceryInputItem {
  final String id;
  String name;
  int quantity;
  double? estimatedPrice; // optional user-provided price hint
  String? barcode;
  String? brand;
  String? productSize;

  GroceryInputItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.estimatedPrice,
    this.barcode,
    this.brand,
    this.productSize,
  });
}
