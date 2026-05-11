import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Read .env file manually
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('.env not found');
    return;
  }
  
  final lines = await envFile.readAsLines();
  String apiKey = '';
  for (final line in lines) {
    if (line.startsWith('GEMINI_API_KEY=') || line.startsWith('OPENAI_API_KEY=')) {
      final key = line.split('=')[1].trim();
      if (!key.contains('your_')) {
        apiKey = key;
        break;
      }
    }
  }

  if (apiKey.isEmpty) {
    print('No valid API key found in .env');
    return;
  }

  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    print('Models available to this key:');
    for (final model in models) {
      print("- ${model['name']}");
    }
  } else {
    print("Failed to list models: ${response.statusCode} - ${response.body}");
  }
}
