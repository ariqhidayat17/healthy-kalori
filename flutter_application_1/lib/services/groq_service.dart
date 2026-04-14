import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String apiKey = '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';
  static const String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant", // Model yang paling stabil dan cepat
          "messages": messages,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }
}
