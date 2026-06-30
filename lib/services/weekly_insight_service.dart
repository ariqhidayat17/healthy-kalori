import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../utils/database_helper.dart';
import '../utils/prefs_service.dart';

/// Menghasilkan ringkasan mingguan berbasis AI menggunakan data lokal user.
///
/// Alur:
/// 1. Kumpulkan data 7 hari terakhir dari DB (kalori, makro, air, workout)
/// 2. Bangun prompt ringkas untuk Gemini
/// 3. Kembalikan teks insight sebagai String
///
/// Weekly insight hanya di-generate sekali per minggu (Senin).
/// Key prefs: 'last_weekly_insight_date' + 'cached_weekly_insight'
class WeeklyInsightService {
  static const _kLastInsightDate  = 'last_weekly_insight_date';
  static const _kCachedInsight    = 'cached_weekly_insight';

  final _fmt = DateFormat('dd/MM/yyyy');

  // ── Public API ────────────────────────────────────────────────────────────

  /// Apakah ada insight minggu ini yang sudah di-cache?
  bool hasCachedInsight() {
    final p = PrefsService.i.raw;
    final lastDate = p.getString(_kLastInsightDate) ?? '';
    final cached   = p.getString(_kCachedInsight)   ?? '';
    if (lastDate.isEmpty || cached.isEmpty) return false;

    // Insight dianggap valid jika dibuat dalam 7 hari terakhir
    try {
      final generated = _fmt.parse(lastDate);
      final diff = DateTime.now().difference(generated).inDays;
      return diff < 7;
    } catch (_) {
      return false;
    }
  }

  /// Ambil insight yang sudah di-cache (tanpa memanggil AI).
  String? getCachedInsight() {
    if (!hasCachedInsight()) return null;
    return PrefsService.i.raw.getString(_kCachedInsight);
  }

  /// Generate insight baru dari Gemini.
  /// Jika [forceRefresh] = false dan cache masih valid, kembalikan cache.
  Future<WeeklyInsightResult> generateInsight({bool forceRefresh = false}) async {
    if (!forceRefresh && hasCachedInsight()) {
      return WeeklyInsightResult(
        insight: getCachedInsight()!,
        isFromCache: true,
      );
    }

    try {
      final data   = await _collectWeeklyData();
      final prompt = _buildPrompt(data);
      final text   = await _callGemini(prompt);

      // Cache hasilnya
      final today = _fmt.format(DateTime.now());
      await PrefsService.i.raw.setString(_kLastInsightDate, today);
      await PrefsService.i.raw.setString(_kCachedInsight, text);

      return WeeklyInsightResult(insight: text, isFromCache: false);
    } catch (e) {
      return WeeklyInsightResult(
        insight: '',
        isFromCache: false,
        error: 'Gagal menghasilkan insight: $e',
      );
    }
  }

  // ── Data collection ───────────────────────────────────────────────────────

  Future<_WeeklyData> _collectWeeklyData() async {
    final now = DateTime.now();
    // 7 hari terakhir (termasuk hari ini)
    final dates = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _fmt.format(d);
    });

    final p = PrefsService.i;

    final dailyCalories = await DatabaseHelper.instance
        .getDailyCaloriesByDates(dates);
    final dailyWater    = await DatabaseHelper.instance
        .getDailyWaterByDates(dates);
    final workoutDays   = await DatabaseHelper.instance
        .getWorkoutCountByDates(dates);
    final latestWeight  = await DatabaseHelper.instance.getLatestWeight();

    return _WeeklyData(
      dates: dates,
      dailyCalories: dailyCalories,
      dailyWater: dailyWater,
      workoutDays: workoutDays,
      targetCalories: p.targetCalories,
      targetProtein: p.targetProtein,
      targetWater: p.targetWater,
      goal: p.goal,
      name: p.name,
      latestWeight: latestWeight?.weight,
    );
  }

  // ── Prompt builder ────────────────────────────────────────────────────────

  String _buildPrompt(_WeeklyData d) {
    // Hitung rata-rata mingguan
    final totalCalories = d.dailyCalories.fold(0, (s, e) => s + (e['calories'] as int));
    final totalProtein  = d.dailyCalories.fold(0, (s, e) => s + (e['protein'] as int));
    final daysLogged    = d.dailyCalories.length;
    final avgCalories   = daysLogged > 0 ? totalCalories ~/ daysLogged : 0;
    final avgProtein    = daysLogged > 0 ? totalProtein  ~/ daysLogged : 0;
    final avgWaterMl    = d.dailyWater.isNotEmpty
        ? d.dailyWater.values.fold(0, (s, v) => s + v) ~/ d.dailyWater.length
        : 0;
    final avgWaterGelas = (avgWaterMl / 250).round();

    // Ringkasan per hari
    final dailySummary = d.dates.map((date) {
      final cal = d.dailyCalories
          .firstWhere((e) => e['date'] == date, orElse: () => {'calories': 0, 'protein': 0})['calories'] as int;
      return '$date: ${cal > 0 ? "$cal kcal" : "tidak ada data"}';
    }).join(', ');

    return '''
Kamu adalah Apex, AI Fitness Coach dalam aplikasi Healthy Calories.
Buat ringkasan mingguan yang singkat (maksimal 4 paragraf, total ~150 kata) dan motivatif dalam bahasa Indonesia.

Data ${d.name} selama 7 hari terakhir:
- Goal: ${d.goal}
- Berat terkini: ${d.latestWeight != null ? "${d.latestWeight} kg" : "belum dicatat"}
- Rata-rata kalori: $avgCalories kcal / hari (target: ${d.targetCalories} kcal)
- Rata-rata protein: $avgProtein g / hari (target: ${d.targetProtein} g)
- Rata-rata air: $avgWaterGelas gelas / hari (target: ${(d.targetWater / 250).round()} gelas)
- Hari dengan workout: ${d.workoutDays} / 7
- Hari dengan data kalori: $daysLogged / 7
- Detail harian: $dailySummary

Format respons (gunakan persis header ini):
**📊 Ringkasan Minggu Ini**
[1-2 kalimat tentang pencapaian keseluruhan]

**💪 Yang Sudah Bagus**
[1-2 poin positif spesifik berdasarkan data]

**⚡ Area Fokus Minggu Depan**
[1-2 saran konkret dan spesifik berdasarkan data]

**🎯 Motivasi**
[1 kalimat penyemangat yang personal]
''';
  }

  // ── Gemini call ───────────────────────────────────────────────────────────

  Future<String> _callGemini(String prompt) async {
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}],
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
    };

    final response = await http
        .post(
          Uri.parse(AppConfig.geminiBaseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('Gemini error ${response.statusCode}');
    }
  }
}

// ── Internal data holder ──────────────────────────────────────────────────

class _WeeklyData {
  final List<String> dates;
  final List<Map<String, dynamic>> dailyCalories;
  final Map<String, int> dailyWater;
  final int workoutDays;
  final int targetCalories;
  final int targetProtein;
  final int targetWater;
  final String goal;
  final String name;
  final double? latestWeight;

  _WeeklyData({
    required this.dates,
    required this.dailyCalories,
    required this.dailyWater,
    required this.workoutDays,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetWater,
    required this.goal,
    required this.name,
    this.latestWeight,
  });
}

/// Hasil dari [WeeklyInsightService.generateInsight].
class WeeklyInsightResult {
  final String insight;
  final bool isFromCache;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;

  const WeeklyInsightResult({
    required this.insight,
    required this.isFromCache,
    this.error,
  });
}
