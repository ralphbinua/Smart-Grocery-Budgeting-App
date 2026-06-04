class CartItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final Map<String, dynamic>? alternative;
  final DateTime addedAt;
  int quantity;
  final double savedAmount;
  final String? note;           // AI quality justification for the alternative
  final List<String> coupons;   // List of deal/coupon strings from AI

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.alternative,
    this.savedAmount = 0.0,
    this.note,
    List<String>? coupons,
    int? quantity,
    DateTime? addedAt,
  })  : quantity = quantity ?? 1,
        coupons = coupons ?? [],
        addedAt = addedAt ?? DateTime.now();

  double get total => price * quantity;
  bool get hasDeals => coupons.isNotEmpty;

  CartItem copyWith({
    int? quantity,
    Map<String, dynamic>? alternative,
    double? savedAmount,
    String? note,
    List<String>? coupons,
  }) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      category: category,
      alternative: alternative ?? this.alternative,
      savedAmount: savedAmount ?? this.savedAmount,
      note: note ?? this.note,
      coupons: coupons ?? this.coupons,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt,
    );
  }
}