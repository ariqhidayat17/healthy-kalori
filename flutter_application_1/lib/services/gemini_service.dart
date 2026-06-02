import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// GeminiService — Layanan AI berbasis Google Gemini 1.5 Flash (Google AI Studio)
/// Menggantikan GroqService untuk chat teks dan analisis foto makanan (Vision).
/// Gratis hingga 1.500 request/hari via Google AI Studio Free Tier.
class GeminiService {
  // ─────────────────────────────────────────────────────────
  // CHAT TEKS (AI Coach)
  // Menerima riwayat pesan berformat {role: 'user'/'assistant', content: '...'}
  // (kompatibel dengan format GroqService lama)
  // ─────────────────────────────────────────────────────────
  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    try {
      // Pisahkan system prompt (role: 'system') dari pesan percakapan biasa
      final systemMessages = messages.where((m) => m['role'] == 'system').toList();
      final conversationMessages = messages.where((m) => m['role'] != 'system').toList();

      // Bangun bagian systemInstruction dari Gemini API
      final systemInstruction = systemMessages.isNotEmpty
          ? {
              'role': 'user',
              'parts': [{'text': systemMessages.map((m) => m['content']).join('\n\n')}],
            }
          : null;

      // Konversi format pesan dari OpenAI-style ke Gemini-style
      // 'assistant' → 'model' (istilah Gemini untuk peran AI)
      final contents = conversationMessages.map((m) {
        return {
          'role': m['role'] == 'assistant' ? 'model' : 'user',
          'parts': [{'text': m['content'] ?? ''}],
        };
      }).toList();

      // Susun body request Gemini
      final body = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        },
      };

      // Tambahkan systemInstruction jika ada
      if (systemInstruction != null) {
        body['systemInstruction'] = systemInstruction;
      }

      final response = await http
          .post(
            Uri.parse(AppConfig.geminiBaseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            Duration(seconds: AppConfig.requestTimeoutSeconds),
            onTimeout: () {
              throw SocketException(
                  'Request timeout setelah ${AppConfig.requestTimeoutSeconds} detik');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else if (response.statusCode == 400) {
        return '❌ **Request tidak valid.** Pastikan format pesan sudah benar.';
      } else if (response.statusCode == 403) {
        return '❌ **API Key tidak valid atau kuota habis.** Cek kunci API Gemini kamu di Google AI Studio.';
      } else if (response.statusCode == 429) {
        return '⏳ **Terlalu banyak permintaan.** Kamu telah melampaui kuota gratis (15 req/menit). Tunggu sebentar dan coba lagi.';
      } else if (response.statusCode >= 500) {
        return '🔧 **Server Google AI sedang bermasalah.** Coba lagi dalam beberapa saat.';
      } else {
        return '❌ **Gagal memuat respons** (kode: ${response.statusCode}). Coba lagi.';
      }
    } on SocketException {
      return '📶 **Koneksi internet bermasalah** atau request timeout. Periksa jaringan kamu dan coba lagi.';
    } catch (e) {
      return '❌ **Terjadi kesalahan tidak terduga.** Coba lagi dalam beberapa saat.';
    }
  }

  // ─────────────────────────────────────────────────────────
  // VISION AI — ANALISIS FOTO MAKANAN
  // Menggunakan JSON Mode Gemini untuk menjamin output selalu JSON bersih.
  // Jauh lebih stabil dibanding Groq Vision yang outputnya kadang berisi markdown.
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // System prompt untuk analisis foto makanan — instruksi ketat agar output JSON valid
      const systemPrompt =
          'Kamu adalah ahli gizi dan pakar computer vision makanan profesional. '
          'Tugas: Analisis foto ini, identifikasi makanan/minuman yang terlihat secara SPESIFIK, '
          'lalu estimasi kandungan gizinya untuk porsi yang terlihat di foto. '
          'Aturan: (1) Identifikasi spesifik (bukan "makanan Indonesia", tapi "Nasi Goreng Kampung"). '
          '(2) Gunakan referensi TKPI untuk makanan Indonesia. '
          '(3) Kalori HARUS konsisten: kalori ≈ (protein×4)+(karbo×4)+(lemak×9). '
          '(4) Kembalikan HANYA nilai numerik integer yang wajar. '
          'Kembalikan HANYA objek JSON dengan format: '
          '{"foodName":"Nama Makanan","calories":0,"protein":0,"carbs":0,"fats":0}';

      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {
                'text':
                    'Analisis foto makanan ini. Identifikasi nama makanan secara spesifik, '
                    'perkirakan porsinya, lalu kembalikan estimasi gizi dalam format JSON yang sudah ditentukan. '
                    'Hanya JSON, tidak ada teks atau markdown lain.',
              },
            ],
          },
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        // JSON Mode — Gemini menjamin output selalu berupa JSON valid, tanpa markdown
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
          'maxOutputTokens': 1500, // Dinaikkan untuk mengakomodasi reasoning tokens
        },
      };

      final response = await http
          .post(
            Uri.parse(AppConfig.geminiBaseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cek apakah response terpotong karena batas token
        final finishReason = data['candidates'][0]['finishReason'];
        if (finishReason == 'MAX_TOKENS') {
          return {'error': '❌ Analisis AI terpotong. Coba lagi.'};
        }

        String jsonString =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
            
        // Pembersih Markdown: berjaga-jaga jika Gemini 3.5 tetap mengirimkan ```json
        if (jsonString.contains('```')) {
          final regex = RegExp(r'```(?:json)?\n?(.*?)\n?```', dotAll: true);
          final match = regex.firstMatch(jsonString);
          if (match != null) {
            jsonString = match.group(1) ?? jsonString;
          }
        }
        
        // Pembersih ekstra jika ada teks pembuka seperti "Here is the JSON requested:"
        final startIdx = jsonString.indexOf('{');
        final endIdx = jsonString.lastIndexOf('}');
        if (startIdx != -1 && endIdx != -1 && endIdx >= startIdx) {
          jsonString = jsonString.substring(startIdx, endIdx + 1);
        }

        final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        return parsedJson;
      } else {
        throw Exception('Vision API Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      return {'error': '📶 Koneksi internet bermasalah. Periksa jaringan kamu.'};
    } on FormatException {
      return {'error': '❌ AI mengembalikan format yang tidak terbaca. Coba foto ulang dengan pencahayaan lebih baik.'};
    } on Exception catch (e) {
      return {'error': e.toString()};
    } catch (e) {
      return {'error': '❌ Terjadi kesalahan tidak terduga.'};
    }
  }
}
