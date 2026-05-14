import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static Future<Map<String, dynamic>?> getAlternative(
    String name,
    double price,
    String category,
  ) async {
    // Look for GROQ_API_KEY, or fallback to OPENAI_API_KEY
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_')) {
      debugPrint('AIService: API Key is missing or invalid.');
      return null;
    }

    final String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

    final prompt =
        '''
The user just scanned a grocery item: '$name' for $price PHP in the category '$category'.
Suggest a cheaper, commonly available alternative product in the Philippines.
Respond STRICTLY with a JSON object containing exactly two keys:
1. "name": the name of the alternative product (String)
2. "price": a reasonable price for it in PHP which MUST be less than $price (Number)
If no realistic cheaper alternative exists, respond with exactly: null
''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant", // Fast and free Llama 3.1 model
          "messages": [
            {
              "role": "system",
              "content": "You are a smart grocery shopping assistant that helps users save money by finding cheaper alternatives."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.3
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] == null || data['choices'].isEmpty) return null;

        String content = data['choices'][0]['message']['content'].toString().trim();

        if (content == 'null' || content.isEmpty) return null;

        // Bulletproof JSON extraction: Find the first { and the last }
        final int startIndex = content.indexOf('{');
        final int endIndex = content.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          final jsonString = content.substring(startIndex, endIndex + 1);
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } else {
          debugPrint('Groq returned invalid format: $content');
          return null;
        }
      } else {
        debugPrint('Groq Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Groq Exception: $e');
      return null;
    }
  }
}
