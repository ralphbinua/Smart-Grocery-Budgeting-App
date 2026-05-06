class CartItem {
  final String name;
  final double price;
  final Map<String, dynamic>? alternative;

  CartItem({
    required this.name,
    required this.price,
    this.alternative,
  });
}