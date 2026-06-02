import 'dart:convert';
import 'dart:io';

void main() async {
  // Baca .env secara manual untuk testing
  final envFile = File('.env');
  final envLines = await envFile.readAsLines();
  String? apiKey;
  for (var line in envLines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('GEMINI_API_KEY tidak ditemukan di .env');
    return;
  }

  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' + apiKey;
  print('URL: ' + url.replaceAll(apiKey, 'HIDDEN'));

  final body = {
    'contents': [
      {
        'role': 'user',
        'parts': [{'text': 'Halo, ini tes 123'}]
      }
    ]
  };

  final request = await HttpClient().postUrl(Uri.parse(url));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status Code: ' + response.statusCode.toString());
  print('Response Body: ' + responseBody);
}
