import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductLookupService {
  static const String _baseUrl =
      'https://smart-grocery-budgeting-app.onrender.com';

  static Future<Map<String, dynamic>?> lookupByBarcode(String barcode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/products/${Uri.encodeComponent(barcode)}'),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ProductLookupException(
        'Barcode lookup failed (${response.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>> saveProduct({
    required String name,
    String? barcode,
    String? brand,
    String? quantity,
    String? category,
    double? latestPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        if (barcode != null && barcode.trim().isNotEmpty)
          'barcode': barcode.trim(),
        if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
        if (quantity != null && quantity.trim().isNotEmpty)
          'quantity': quantity.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        ...?(latestPrice == null ? null : {'latestPrice': latestPrice}),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ProductLookupException(
        'Could not save the product (${response.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>?> matchProductName({
    required String name,
    String? brand,
    String? quantity,
  }) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/products'));
    if (response.statusCode != 200) {
      throw ProductLookupException(
        'Product database lookup failed (${response.statusCode}).',
      );
    }

    final rawProducts = jsonDecode(response.body) as List;
    final candidateName = _normalize(name);
    final candidateBrand = _normalize(brand ?? '');
    final candidateQuantity = _normalize(quantity ?? '');
    final candidateFull = _normalize('$name ${brand ?? ''} ${quantity ?? ''}');

    final matches = rawProducts
        .whereType<Map>()
        .where((rawProduct) {
          final product = Map<String, dynamic>.from(rawProduct);
          final productName = _normalize(product['name']?.toString() ?? '');
          final productBrand = _normalize(product['brand']?.toString() ?? '');
          final productQuantity = _normalize(
            product['quantity']?.toString() ?? '',
          );
          final productFull = _normalize(
            '${product['name'] ?? ''} ${product['brand'] ?? ''} ${product['quantity'] ?? ''}',
          );

          final nameMatches =
              candidateName == productName ||
              candidateFull.contains(productName) ||
              productFull.contains(candidateName);
          if (!nameMatches) return false;

          if (candidateBrand.isNotEmpty) {
            if (productBrand.isNotEmpty && candidateBrand != productBrand) {
              return false;
            }
            if (productBrand.isEmpty && !productName.contains(candidateBrand)) {
              return false;
            }
          }
          if (productBrand.isNotEmpty &&
              candidateBrand.isEmpty &&
              !candidateName.contains(productBrand)) {
            return false;
          }

          if (candidateQuantity.isNotEmpty) {
            if (productQuantity.isNotEmpty &&
                candidateQuantity != productQuantity) {
              return false;
            }
            if (productQuantity.isEmpty &&
                !productName.contains(candidateQuantity)) {
              return false;
            }
          }
          if (productQuantity.isNotEmpty &&
              candidateQuantity.isEmpty &&
              !candidateName.contains(productQuantity)) {
            return false;
          }

          return true;
        })
        .map((rawProduct) => Map<String, dynamic>.from(rawProduct))
        .toList();

    return matches.length == 1 ? matches.single : null;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class ProductLookupException implements Exception {
  final String message;

  const ProductLookupException(this.message);

  @override
  String toString() => message;
}
