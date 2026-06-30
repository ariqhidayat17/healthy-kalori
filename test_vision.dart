import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  final envLines = await envFile.readAsLines();
  String? apiKey;
  for (var line in envLines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) return;

  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=' + apiKey;

  // Pixel 1x1 base64 image (dummy image)
  final base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  const systemPrompt =
      'Kamu adalah ahli gizi. Kembalikan HANYA objek JSON dengan format: '
      '{"foodName":"Nama Makanan","calories":0,"protein":0,"carbs":0,"fats":0}';

  final body = {
    'contents': [
      {
        'role': 'user',
        'parts': [
          {
            'inlineData': {
              'mimeType': 'image/png',
              'data': base64Image,
            },
          },
          {
            'text': 'Analisis foto makanan ini.',
          },
        ],
      },
    ],
    'systemInstruction': {
      'parts': [
        {'text': systemPrompt},
      ],
    },
    'generationConfig': {
      'responseMimeType': 'application/json',
      'temperature': 0.1,
      'maxOutputTokens': 300,
    },
  };

  final request = await HttpClient().postUrl(Uri.parse(url));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status Code: ' + response.statusCode.toString());
  print('Response Body: ' + responseBody);
}
