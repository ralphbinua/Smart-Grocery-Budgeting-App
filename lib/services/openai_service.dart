import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static Future<Map<String, dynamic>?> getAlternative(String name, double price, String category) async {
    // Falls back to checking OPENAI_API_KEY in case you pasted it there
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_')) {
      debugPrint('AIService: API Key is missing or invalid.');
      return null;
    }

    final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey';

    final prompt = '''
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
        },
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": "You are a smart grocery shopping assistant that helps users save money by finding cheaper alternatives.\n\n" + prompt}]
          }],
          "generationConfig": {
            "temperature": 0.3
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) return null;
        
        String content = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        
        // Remove markdown JSON codeblocks if Gemini added them
        if (content.startsWith('```json')) {
          content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        }
        
        if (content == 'null' || content.isEmpty) return null;
        
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        debugPrint('Gemini Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      return null;
    }
  }
}
