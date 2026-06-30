import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = "AIzaSyDmIE78OkamR09008Ih--U1u5HhQZlfWJM";
  final url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey";
  
  // Chat Payload
  final chatBody = {
    'contents': [
      {'role': 'user', 'parts': [{'text': 'Hello'}]}
    ],
    'systemInstruction': {
      'role': 'user',
      'parts': [{'text': 'You are a helpful AI.'}]
    },
    'generationConfig': {
      'temperature': 0.7,
      'maxOutputTokens': 2048,
    },
  };
  
  print("Testing Chat...");
  var res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode(chatBody));
  print(res.statusCode);
  print(res.body);

  // Vision Payload
  final visionBody = {
    'contents': [
      {
        'role': 'user',
        'parts': [
          {
            'inlineData': {
              'mimeType': 'image/jpeg',
              'data': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
            },
          },
          {'text': 'Analisis foto makanan ini.'}
        ]
      }
    ],
    'systemInstruction': {
      'parts': [{'text': 'Kamu ahli gizi.'}]
    },
    'generationConfig': {
      'responseMimeType': 'application/json',
      'temperature': 0.1,
      'maxOutputTokens': 1500,
    },
  };
  
  print("\nTesting Vision...");
  res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode(visionBody));
  print(res.statusCode);
  print(res.body);
}
