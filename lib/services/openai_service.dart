import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/grocery_input_item.dart';

class AIService {
  static String get _apiKey =>
      dotenv.env['GROQ_API_KEY'] ??
      dotenv.env['OPENAI_API_KEY'] ??
      dotenv.env['GEMINI_API_KEY'] ??
      '';

  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // ─── Batch Grocery List Analysis ────────────────────────────────────────────
  /// Analyzes a full grocery list in a single AI call.
  /// Returns a list of enriched result maps, one per input item:
  /// {
  ///   "name": "original name",
  ///   "price": 98.0,
  ///   "category": "Dairy",
  ///   "alternative": { "name": "...", "price": 65.0 } | null,
  ///   "note": "Same nutritional value, store brand",
  ///   "coupons": ["Buy 1 Take 1 at SM Supermarket", "On sale at Puregold"]
  /// }
  static Future<List<Map<String, dynamic>>> analyzeGroceryList(
    List<GroceryInputItem> items, {
    Map<String, Map<String, dynamic>>? dbGroundingData,
  }) async {
    if (_apiKey.isEmpty || _apiKey.contains('your_')) {
      debugPrint('AIService: API Key is missing or invalid.');
      return _buildFallbackResults(items);
    }

    final itemsJson = items.map((i) {
      final grounding = dbGroundingData?[i.name.toLowerCase().trim()];
      return {
        'name': i.name,
        'quantity': i.quantity,
        if (grounding != null) 'dbPrice': grounding['price'],
        if (grounding != null) 'dbCategory': grounding['category'],
        if (grounding != null) 'dbIsPromo': grounding['isPromo'],
        if (grounding != null && (grounding['promoLabel'] as String? ?? '').isNotEmpty)
          'dbPromoLabel': grounding['promoLabel'],
        if (grounding != null && (grounding['promoStore'] as String? ?? '').isNotEmpty)
          'dbPromoStore': grounding['promoStore'],
        if (grounding != null && (grounding['promoDiscount'] ?? 0) > 0)
          'dbPromoDiscount': grounding['promoDiscount'],
        if (i.estimatedPrice != null && grounding == null)
          'estimatedPrice': i.estimatedPrice,
      };
    }).toList();

    final prompt = '''
You are a smart grocery shopping assistant for the Philippines. The user is planning to buy the following items:

${jsonEncode(itemsJson)}

For EACH item in the list, provide a JSON object with:
1. "name" (String) — the original product name. If "dbPrice" is active, please keep the exact product name from the database.
2. "price" (Number) — a realistic price in Philippine Peso (PHP) for that item.
   - CRITICAL: If "dbPrice" is provided, you MUST use that exact "dbPrice" value.
   - If "dbPrice" is not provided, use the "estimatedPrice" if provided, otherwise estimate a realistic market price.
3. "category" (String) — If "dbCategory" is provided, you MUST use that exact category. Otherwise, use one of: Dairy, Bakery, Beverages, Snacks, Meat, Canned Goods, Instant Food, Produce, Condiments, Personal Care, Household, Frozen, General.
4. "alternative" (Object or null) — if a cheaper, commonly available alternative exists in PH:
   { "name": "...", "price": <number less than price> }
   CRITICAL: The alternative MUST be a real, specific product brand commonly available in major Philippine supermarkets (e.g. Puregold, SM Supermarket, Robinsons). 
   Never suggest generic placeholder names (like "Alternative Milk", "Brand B Milk", "Cheaper Brand").
   Examples:
   - For "Nestle Fresh Milk", suggest "Cowhead Pure Milk" or "Magnolia Fresh Milk".
   - For "Argentina Corned Beef", suggest "555 Corned Beef" or "Star Corned Beef".
   - For "Century Tuna", suggest "555 Tuna" or "Mega Tuna".
   - For "Safeguard Soap", suggest "Bioderm Soap" or "Guard Soap".
   Set to null if no realistic cheaper option exists.
5. "note" (String) — a short reason why the alternative is still a good quality choice (e.g. "Same weight, popular local brand"). Empty string if no alternative.
6. "coupons" (Array of strings) — list of any real promotions or sales in Philippine supermarkets (e.g. ["Buy 1 Take 1 at SM Supermarket", "On sale at Puregold"]).
   - CRITICAL: If "dbIsPromo" is true, it means this product currently has a verified promotion in our database.
     - If "dbPromoLabel" is provided, use it EXACTLY as the first coupon string.
     - If "dbPromoDiscount" is provided, append "– X% OFF" to the label.
     - If "dbPromoStore" is provided, append "@ StoreName" to the coupon string.
     - Example: dbPromoLabel="Buy 2 Get 1 Free", dbPromoDiscount=33, dbPromoStore="7-Eleven" → "Buy 2 Get 1 Free – 33% OFF @ 7-Eleven"
   - If no active promo is specified by "dbIsPromo", you can still suggest generic known coupons/sales. Empty array if none.

Here is an example of the expected output format:
Input: [{"name": "Nestle Fresh Milk 1L", "quantity": 1}]
Output: [{"name": "Nestle Fresh Milk 1L", "price": 105.0, "category": "Dairy", "alternative": {"name": "Cowhead Pure Milk 1L", "price": 88.0}, "note": "Cowhead is a popular imported brand, widely available in PH and cheaper than Nestle.", "coupons": ["₱10 off at Puregold"]}]

Respond STRICTLY with a JSON array containing one object per input item, in the same order.
Do NOT include any explanation text — only the JSON array.
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a smart grocery assistant for major Philippine supermarkets (like SM, Puregold, Robinsons). You must ONLY suggest real, specific local brands sold in the Philippines (e.g. Century Tuna, Mega Sardines, Magnolia, Selecta, Lucky Me!, Datu Puti, Piattos, Safeguard, Breeze). Never suggest generic terms like "Brand B Milk" or "Alternative Tuna". Always respond with valid JSON only.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] == null || data['choices'].isEmpty) {
          return _buildFallbackResults(items);
        }

        String content =
            data['choices'][0]['message']['content'].toString().trim();

        // Extract JSON array
        final startIndex = content.indexOf('[');
        final endIndex = content.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          final jsonString = content.substring(startIndex, endIndex + 1);
          final parsed = jsonDecode(jsonString) as List;
          return List<Map<String, dynamic>>.from(parsed);
        } else {
          debugPrint('AIService: Invalid array format from AI: $content');
          return _buildFallbackResults(items);
        }
      } else {
        debugPrint(
            'AIService Error: ${response.statusCode} - ${response.body}');
        return _buildFallbackResults(items);
      }
    } catch (e) {
      debugPrint('AIService Exception: $e');
      return _buildFallbackResults(items);
    }
  }


  // ─── Fallback Results (when AI unavailable) ─────────────────────────────────
  static List<Map<String, dynamic>> _buildFallbackResults(
      List<GroceryInputItem> items) {
    return items.map((item) {
      final price = item.estimatedPrice ?? 50.0;
      return {
        'name': item.name,
        'price': price,
        'category': 'General',
        'alternative': null,
        'note': '',
        'coupons': <String>[],
      };
    }).toList();
  }
}
