import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../config/app_config.dart';

class GroqService {
  // Kirim pesan ke Groq API dan kembalikan respons teks
  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.groqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': AppConfig.groqModel,
              'messages': messages,
              'temperature': 0.7,
            }),
          )
          .timeout(
            Duration(seconds: AppConfig.requestTimeoutSeconds),
            onTimeout: () {
              throw SocketException('Request timeout setelah ${AppConfig.requestTimeoutSeconds} detik');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else if (response.statusCode == 401) {
        return '❌ **Autentikasi gagal.** API key tidak valid atau sudah kedaluwarsa.';
      } else if (response.statusCode == 429) {
        return '⏳ **Terlalu banyak permintaan.** Coba lagi dalam beberapa detik.';
      } else if (response.statusCode >= 500) {
        return '🔧 **Server AI sedang bermasalah.** Coba lagi sebentar lagi.';
      } else {
        return '❌ **Gagal memuat respons** (kode: ${response.statusCode}). Coba lagi.';
      }
    } on SocketException {
      return '📶 **Koneksi internet bermasalah** atau request timeout. Periksa jaringan kamu dan coba lagi.';
    } catch (e) {
      return '❌ **Terjadi kesalahan tidak terduga.** Coba lagi dalam beberapa saat.';
    }
  }

  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      // Resize gambar ke max 1024px sebelum encode agar tidak OOM / timeout
      final Uint8List originalBytes = await imageFile.readAsBytes();
      final img.Image? decoded = img.decodeImage(originalBytes);
      Uint8List bytes;
      if (decoded != null) {
        final img.Image resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? 1024 : -1,
          height: decoded.width <= decoded.height ? 1024 : -1,
        );
        bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      } else {
        bytes = originalBytes;
      }
      final base64Image = base64Encode(bytes);

      // System prompt khusus untuk mengembalikan raw JSON tanpa tambahan teks
      final systemPrompt = '''
Kamu adalah ahli gizi dan computer vision makanan profesional.
Tugasmu: Analisis foto ini dan identifikasi makanan/minuman yang terlihat, lalu estimasi kandungan gizinya secara akurat.

ATURAN IDENTIFIKASI:
1. Identifikasi makanan/minuman dengan SPESIFIK. Contoh bukan "Makanan Indonesia" tapi "Nasi Goreng Kampung" atau "Bubur Ayam".
2. Untuk makanan kemasan: baca nama produk yang terlihat di kemasan jika ada.
3. Untuk makanan Indonesia: gunakan referensi TKPI (Tabel Komposisi Pangan Indonesia).
4. Perkirakan PORSI yang terlihat di foto (bukan per 100g), lalu hitung total gizinya untuk porsi tersebut.
5. Kalori HARUS konsisten: kalori ≈ (protein × 4) + (karbo × 4) + (lemak × 9). Jangan ada inkonsistensi.
6. Jangan menebak-nebak sembarangan. Jika tidak yakin, beri estimasi yang KONSERVATIF (angka tengah).

KEMBALIKAN HANYA OBJEK JSON MURNI TANPA MARKDOWN, TANPA KOMENTAR, TANPA TEKS LAIN.
Format wajib:
{
  "foodName": "Nama Spesifik Makanan",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fats": 0
}''';

      final requestPayload = {
        'model': AppConfig.groqVisionModel,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              },
              {
                'type': 'text',
                'text': 'Analisis foto makanan ini. Identifikasi nama makanan secara spesifik, perkirakan porsinya, lalu kembalikan estimasi gizi dalam format JSON yang sudah ditentukan. Hanya JSON, tidak ada teks lain.'
              },
            ]
          }
        ],
        'temperature': 0.1, // Suhu rendah agar stabil dan konsisten output JSON-nya
        'max_tokens': 300,
      };

      final response = await http
          .post(
            Uri.parse(AppConfig.groqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode(requestPayload),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'] as String;
        
        // Coba bersihkan JSON jika model tetap membandel mengeluarkan markdown ```json
        final jsonString = answer.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        return parsedJson;
      } else {
        final errorMsg = 'Vision API Error ${response.statusCode}: ${response.body}';
        throw Exception(errorMsg);
      }
    } on SocketException {
      return {'error': '📶 Koneksi internet bermasalah. Periksa jaringan kamu.'};
    } on Exception catch (e) {
      return {'error': e.toString()};
    } catch (e) {
      return {'error': '❌ Terjadi kesalahan tidak terduga.'};
    }
  }
}
