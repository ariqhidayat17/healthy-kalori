import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gemini_service.dart';
import '../models/calorie_provider.dart';
import '../utils/prefs_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/fantasy_card.dart';
import '../widgets/fantasy_quick_action_chip.dart';
import '../widgets/apex_avatar_header.dart';
import '../widgets/food_recommendation_card.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();

  // Pesan yang ditampilkan di UI (tidak termasuk system prompt)
  final List<Map<String, String>> _displayMessages = [];

  List<String> _suggestedQuestions = [];
  final List<String> _allQuestions = [
    "Berapa target protein saya hari ini?",
    "Apa menu bulking yang direkomendasikan?",
    "Bagaimana progres kalori saya?",
    "Tips untuk menambah massa otot",
    "Saran camilan sehat tinggi protein",
  ];

  // Semua pesan yang dikirim ke API (termasuk system prompt)
  final List<Map<String, String>> _apiMessages = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  static const String _prefsKey = 'ai_chat_history';

  @override
  void initState() {
    super.initState();
    _allQuestions.shuffle();
    _suggestedQuestions = _allQuestions.take(4).toList();
    _initCoach();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Inisialisasi: muat profil, bangun system prompt, load riwayat
  Future<void> _initCoach() async {
    final prefs = PrefsService.i;
    final name = prefs.name;
    final age = prefs.age;
    final weight = prefs.weight;
    final height = prefs.height;
    final gender = prefs.gender;
    final activityLevel = prefs.activityLevel;
    final goal = prefs.goal;

    final calorieProvider = context.read<CalorieProvider>();
    final consumed = calorieProvider.totalConsumedCalories;
    final target = calorieProvider.targetCalories;
    final p = calorieProvider.totalConsumedProtein;
    final tp = calorieProvider.targetProtein;
    final c = calorieProvider.totalConsumedCarbs;
    final tc = calorieProvider.targetCarbs;
    final f = calorieProvider.totalConsumedFats;
    final tf = calorieProvider.targetFats;

    // Bangun system prompt (selalu paling awal, tidak ditampilkan di UI)
    final systemPrompt = {
      'role': 'system',
      'content': '''Kamu adalah **Apex**, AI Fitness Coach pribadi yang berpenampilan seperti Wise Trainer dari game RPG fantasy. Kamu beroperasi di dalam aplikasi "Healthy Calories" — pelacak kalori dan makronutrisi untuk binaragawan.

### Kepribadian Apex:
- Ramah dan bijaksana seperti mentor/trainer di game RPG (vibe kakek bijak atau guru bela diri).
- Menggunakan bahasa Indonesia yang natural, hangat, dan memotivasi.
- Suka menggunakan referensi game/fantasy (misal: "Quest proteinmu hari ini!", "Level up kekuatanmu!").
- Selalu mendasarkan saran pada data user real-time yang diberikan di bawah.

### Data Real-time User ($name):
• Kalori: $consumed / $target kcal
• Protein: ${p}g / ${tp}g
• Karbohidrat: ${c}g / ${tc}g
• Lemak: ${f}g / ${tf}g
• Tujuan: $goal
• Info Tubuh: $weight kg, $height cm, $age tahun, $gender.

### Aturan Respons:
1. Singkat, padat, dan penuh motivasi (maksimal 3 paragraf).
2. Gunakan emoji yang relevan (🧙‍♂️, 💪, 🍗, ⚡, 🥗).
3. Jika protein kurang, ingatkan dengan cara yang seru.
4. Jika user mencapai target, beri selamat seperti reward quest.
5. Saat rekomendasi makanan, gunakan format:
   🍗 **[Nama Makanan]**
   • Kalori: X kcal | Protein: Xg | Karbo: Xg | Lemak: Xg
   [Kenapa ini cocok untuk quest user saat ini]
6. Tetap berikan disclaimer medis jika memberikan saran spesifik.''',
    };

    _apiMessages.add(systemPrompt);

    // Muat riwayat percakapan
    final savedHistory = PrefsService.i.aiChatHistory;
    if (savedHistory != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedHistory);
        final history = decoded.cast<Map<String, dynamic>>().map((m) {
          return {'role': m['role'] as String, 'content': m['content'] as String};
        }).toList();

        // Tambahkan riwayat ke API messages dan display messages
        for (var msg in history) {
          if (msg['role'] == 'user' || msg['role'] == 'assistant') {
            _displayMessages.add(msg);
            _apiMessages.add(msg);
          }
        }
      } catch (e) {
        debugPrint("Gagal memuat riwayat: $e");
      }
    }

    setState(() {
      _isInitialized = true;
    });

    _scrollToBottom();
  }

  // Simpan riwayat (dibatasi 100 pesan terakhir)
  Future<void> _saveHistory() async {
    final capped = _displayMessages.length > 100
        ? _displayMessages.sublist(_displayMessages.length - 100)
        : _displayMessages;
    await PrefsService.i.setAiChatHistory(jsonEncode(capped));
  }

  // Hapus semua riwayat
  Future<void> _clearHistory() async {
    await PrefsService.i.clearAiChatHistory();
    setState(() {
      _displayMessages.clear();
      _apiMessages.clear();
      // Bangun ulang system prompt
      _initCoach();
    });
  }

  // ── Parser rekomendasi makanan dari respons Apex ────────────────────────
  //
  // Mendeteksi format: 🍗 **Nama Makanan**\n• Kalori: 330 kcal | Protein: 62g | Karbo: Xg | Lemak: 7g
  // Mengembalikan null jika tidak ada match (pesan biasa).
  _ParsedFoodRec? _parseFoodRecommendation(String content) {
    final nameMatch = RegExp(r'[\p{Emoji}]\s*\*\*(.+?)\*\*', unicode: true).firstMatch(content);
    final statsMatch = RegExp(
      r'Kalori:\s*(\d+)\s*kcal.*?Protein:\s*(\d+)\s*g(?:.*?Karbo(?:hidrat)?:\s*(\d+)\s*g)?.*?Lemak:\s*(\d+)\s*g',
      caseSensitive: false,
    ).firstMatch(content);

    if (nameMatch == null || statsMatch == null) return null;

    return _ParsedFoodRec(
      name: nameMatch.group(1)?.trim() ?? 'Makanan',
      calories: int.tryParse(statsMatch.group(1) ?? '0') ?? 0,
      protein: int.tryParse(statsMatch.group(2) ?? '0') ?? 0,
      carbs: int.tryParse(statsMatch.group(3) ?? '0') ?? 0,
      fats: int.tryParse(statsMatch.group(4) ?? '0') ?? 0,
    );
  }

  String _rarityForCalories(int calories, int protein) {
    if (calories <= 0) return 'Common';
    final ratio = (protein * 4) / calories;
    if (ratio > 0.6) return 'Legendary';
    if (ratio > 0.3) return 'Epic';
    if (ratio > 0.15) return 'Rare';
    return 'Common';
  }

  Future<void> _addRecommendationToLog(_ParsedFoodRec rec) async {
    final provider = context.read<CalorieProvider>();
    await provider.addFood(
      rec.name,
      rec.calories,
      protein: rec.protein,
      carbs: rec.carbs,
      fats: rec.fats,
      rarity: _rarityForCalories(rec.calories, rec.protein),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${rec.name} ditambahkan ke log! ⚔️'),
          backgroundColor: AppColors.kNatureGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Scroll ListView ke bawah
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Kirim pesan
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final userMsg = {'role': 'user', 'content': text};

    setState(() {
      _displayMessages.add(userMsg);
      _apiMessages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    // Kirim ke API menggunakan API messages (dengan konteks)
    final response = await _geminiService.getChatResponse(_apiMessages);

    final assistantMsg = {'role': 'assistant', 'content': response};

    setState(() {
      _displayMessages.add(assistantMsg);
      _apiMessages.add(assistantMsg);
      _isLoading = false;
    });

    // Batasi panjang _apiMessages agar tidak overflow token (sistem + maks 20 pesan terakhir)
    if (_apiMessages.length > 21) {
      final systemMsg = _apiMessages.first; // Pertahankan system prompt
      final trimmed = _apiMessages.sublist(_apiMessages.length - 20);
      _apiMessages
        ..clear()
        ..add(systemMsg)
        ..addAll(trimmed);
    }

    // Simpan riwayat setelah mendapat balasan
    await _saveHistory();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgCream,
      appBar: RPGAppBar(screenKey: 'apex'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryOrange))
            : Column(
                children: [
                  Expanded(
                    child: _displayMessages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _displayMessages.length,
                            itemBuilder: (context, index) {
                              final msg = _displayMessages[index];
                              final isUser = msg['role'] == 'user';
                              final content = msg['content']!;

                              // Cek apakah ini rekomendasi makanan terstruktur
                              final foodRec = !isUser ? _parseFoodRecommendation(content) : null;

                              return ChatBubble(
                                message: content,
                                type: isUser ? ChatMessageType.user : ChatMessageType.apex,
                                time: DateFormat('HH:mm').format(DateTime.now()),
                                richContent: foodRec != null
                                    ? FoodRecommendationCard(
                                        foodName: foodRec.name,
                                        rarity: _rarityForCalories(foodRec.calories, foodRec.protein),
                                        calories: foodRec.calories,
                                        protein: foodRec.protein,
                                        carbs: foodRec.carbs,
                                        fats: foodRec.fats,
                                        onAddToLog: () => _addRecommendationToLog(foodRec),
                                      )
                                    : null,
                              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                            },
                          ),
                  ),
                  if (_isLoading) _buildTypingIndicator(),
                  _buildInputArea(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final calorieProvider = context.watch<CalorieProvider>();
    final proteinGap = (calorieProvider.targetProtein - calorieProvider.totalConsumedProtein)
        .clamp(0, calorieProvider.targetProtein);
    final name = PrefsService.i.name.split(' ').first;

    final greeting = ApexGreetingBuilder.build(name: name, proteinGap: proteinGap);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          ApexAvatarHeader(
            greeting: greeting.text,
            highlights: greeting.highlights,
          ),
          const SizedBox(height: 24),
          _buildQuickActionsRow(),
        ],
      ),
    );
  }

  // Quick action chips — sesuai desain Stitch: Tips | Makanan | Analisis | ...
  Widget _buildQuickActionsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FantasyQuickActionChip(
            label: 'Tips',
            icon: '💡',
            isActive: true,
            onTap: () {
              _controller.text = "Berikan tips harian untuk saya hari ini.";
              _sendMessage();
            },
          ),
          const SizedBox(width: 8),
          FantasyQuickActionChip(
            label: 'Makanan',
            icon: '🍽️',
            onTap: () {
              _controller.text = "Rekomendasikan makanan sehat untuk sisa kalori saya.";
              _sendMessage();
            },
          ),
          const SizedBox(width: 8),
          FantasyQuickActionChip(
            label: 'Analisis',
            icon: '📊',
            onTap: () {
              _controller.text = "Analisis progres kalori dan makro saya hari ini.";
              _sendMessage();
            },
          ),
          const SizedBox(width: 8),
          FantasyQuickActionChip(
            label: 'Workout',
            icon: '💪',
            onTap: () {
              _controller.text = "Apa saran latihan untuk goal saya saat ini?";
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          _buildApexMiniAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kPrimaryGold.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApexMiniAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.kGradientSunset,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Center(child: Text('🧙‍♂️', style: TextStyle(fontSize: 16))),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.kBgCream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Tanya Apex...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppColors.kGradientSunset,
                color: _isLoading ? Colors.grey[300] : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading ? [] : [
                  BoxShadow(
                    color: AppColors.kPrimaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Riwayat Chat?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text(
            'Semua percakapan dengan AI Coach akan dihapus dan sesi baru akan dimulai.', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ParsedFoodRec {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const _ParsedFoodRec({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
