import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ProductIdentification {
  final String name;
  final String? brand;
  final String? quantity;

  const ProductIdentification({required this.name, this.brand, this.quantity});
}

class ProductVisionService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const int _maxImageBytes = 12 * 1024 * 1024;

  static Future<ProductIdentification?> identifyProduct({
    required Uint8List imageBytes,
    required String barcode,
  }) async {
    if (_apiKey.isEmpty || _apiKey.contains('your_')) {
      debugPrint('ProductVisionService: API key is missing or invalid.');
      return null;
    }
    if (imageBytes.isEmpty || imageBytes.length > _maxImageBytes) {
      debugPrint('ProductVisionService: Image is empty or too large.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'qwen/qwen3.8-27b',
          'temperature': 0.1,
          'max_completion_tokens': 400,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content':
                  'Read the visible product identity from the package photo. The barcode is context only and is not enough to identify a product. Do not guess unreadable text. Return one JSON object with readable (boolean), name (string), brand (string), and quantity (string). Set readable false and name empty if the identity is not legible.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Identify the exact product shown on the package label. Scanned barcode: $barcode. Transcribe the product name, brand, and package size as printed. Do not infer a different product from the barcode.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
                  },
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ProductVisionService error: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = responseData['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final content = choices.first['message']?['content']?.toString();
      if (content == null || content.isEmpty) return null;
      final identity = jsonDecode(content) as Map<String, dynamic>;
      if (identity['readable'] != true) return null;

      final name = identity['name']?.toString().trim() ?? '';
      if (name.isEmpty) return null;

      String? optionalText(String key) {
        final value = identity[key]?.toString().trim();
        return value == null || value.isEmpty ? null : value;
      }

      return ProductIdentification(
        name: name,
        brand: optionalText('brand'),
        quantity: optionalText('quantity'),
      );
    } catch (error) {
      debugPrint('ProductVisionService exception: $error');
      return null;
    }
  }
}
