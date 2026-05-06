class Product {
  final String barcode;
  final String name;
  final double price;
  final String category;
  final String? alternativeName;
  final double? alternativePrice;

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.category,
    this.alternativeName,
    this.alternativePrice,
  });

  // Factory to convert JSON from your Node.js/MongoDB backend
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode'],
      name: json['name'],
      price: json['price'].toDouble(),
      category: json['category'],
      alternativeName: json['alternative']?['name'],
      alternativePrice: json['alternative']?['price']?.toDouble(),
    );
  }
}
