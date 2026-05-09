class CartItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String barcode;
  final Map<String, dynamic>? alternative;
  final DateTime scannedAt;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.barcode,
    this.alternative,
    int? quantity,
    DateTime? scannedAt,
  })  : quantity = quantity ?? 1,
        scannedAt = scannedAt ?? DateTime.now();

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      category: category,
      barcode: barcode,
      alternative: alternative,
      quantity: quantity ?? this.quantity,
      scannedAt: scannedAt,
    );
  }
}