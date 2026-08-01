import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gemini_service.dart';
import '../models/calorie_provider.dart';
import '../utils/prefs_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/fantasy_card.dart';
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

  final List<Map<String, String>> _displayMessages = [];

  final List<String> _allQuestions = [
    "Berapa target protein saya hari ini?",
    "Apa menu bulking yang direkomendasikan?",
    "Bagaimana progres kalori saya?",
    "Tips untuk menambah massa otot",
    "Saran camilan sehat tinggi protein",
  ];

  final List<Map<String, String>> _apiMessages = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _allQuestions.shuffle();
    _initCoach();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initCoach() async {
    final prefs = PrefsService.i;
    final name = prefs.name;
    final age = prefs.age;
    final weight = prefs.weight;
    final height = prefs.height;
    final gender = prefs.gender;
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

    final systemPrompt = {
      'role': 'system',
      'content':
          '''Kamu adalah **Apex**, AI Fitness Coach pribadi yang berpenampilan seperti Wise Trainer dari game RPG fantasy. Kamu beroperasi di dalam aplikasi "Healthy Calories" — pelacak kalori dan makronutrisi untuk binaragawan.

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

    final savedHistory = PrefsService.i.aiChatHistory;
    if (savedHistory != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedHistory);
        final history = decoded.cast<Map<String, dynamic>>().map((m) {
          return {
            'role': m['role'] as String,
            'content': m['content'] as String
          };
        }).toList();

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

  Future<void> _saveHistory() async {
    final capped = _displayMessages.length > 100
        ? _displayMessages.sublist(_displayMessages.length - 100)
        : _displayMessages;
    await PrefsService.i.setAiChatHistory(jsonEncode(capped));
  }

  Future<void> _clearHistory() async {
    await PrefsService.i.clearAiChatHistory();
    setState(() {
      _displayMessages.clear();
      _apiMessages.clear();
      _initCoach();
    });
  }

  _ParsedFoodRec? _parseFoodRecommendation(String content) {
    final nameMatch =
        RegExp(r'[\p{Emoji}]\s*\*\*(.+?)\*\*', unicode: true).firstMatch(content);
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

    final response = await _geminiService.getChatResponse(_apiMessages);
    final assistantMsg = {'role': 'assistant', 'content': response};

    setState(() {
      _displayMessages.add(assistantMsg);
      _apiMessages.add(assistantMsg);
      _isLoading = false;
    });

    if (_apiMessages.length > 21) {
      final systemMsg = _apiMessages.first;
      final trimmed = _apiMessages.sublist(_apiMessages.length - 20);
      _apiMessages
        ..clear()
        ..add(systemMsg)
        ..addAll(trimmed);
    }

    await _saveHistory();
    _scrollToBottom();
  }

  // ── Quest Status Bar ──────────────────────────────────────────────────
  Widget _buildQuestStatusBar() {
    final provider = context.watch<CalorieProvider>();
    final caloriePercent =
        (provider.totalConsumedCalories / provider.targetCalories)
            .clamp(0.0, 1.0);
    final proteinPercent =
        (provider.totalConsumedProtein / provider.targetProtein)
            .clamp(0.0, 1.0);

    return FantasyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📜', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Quest Harian',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.kPrimaryGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    size: 18, color: Colors.redAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _showClearHistoryDialog,
                tooltip: 'Hapus Riwayat',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuestMetric(
                  icon: '⚡',
                  label: 'Energi',
                  value:
                      '${provider.totalConsumedCalories} / ${provider.targetCalories} kcal',
                  percent: caloriePercent,
                  color: AppColors.kPrimaryOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuestMetric(
                  icon: '💪',
                  label: 'Protein',
                  value:
                      '${provider.totalConsumedProtein.toStringAsFixed(0)}g / ${provider.targetProtein.toStringAsFixed(0)}g',
                  percent: proteinPercent,
                  color: AppColors.kPrimaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestMetric({
    required String icon,
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RPGAppBar(screenKey: 'apex'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: !_isInitialized
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.kPrimaryOrange))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: _buildQuestStatusBar(),
                  ),
                  Expanded(
                    child: _displayMessages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _displayMessages.length,
                            itemBuilder: (context, index) {
                              final msg = _displayMessages[index];
                              final isUser = msg['role'] == 'user';
                              final content = msg['content']!;

                              final foodRec = !isUser
                                  ? _parseFoodRecommendation(content)
                                  : null;

                              return ChatBubble(
                                message: content,
                                type: isUser
                                    ? ChatMessageType.user
                                    : ChatMessageType.apex,
                                time: DateFormat('HH:mm')
                                    .format(DateTime.now()),
                                richContent: foodRec != null
                                    ? FoodRecommendationCard(
                                        foodName: foodRec.name,
                                        rarity: _rarityForCalories(
                                            foodRec.calories, foodRec.protein),
                                        calories: foodRec.calories,
                                        protein: foodRec.protein,
                                        carbs: foodRec.carbs,
                                        fats: foodRec.fats,
                                        onAddToLog: () =>
                                            _addRecommendationToLog(foodRec),
                                      )
                                    : null,
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1);
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

  // ── Empty State — RPG Welcome ─────────────────────────────────────────
  Widget _buildEmptyState() {
    final calorieProvider = context.watch<CalorieProvider>();
    final proteinGap =
        (calorieProvider.targetProtein - calorieProvider.totalConsumedProtein)
            .clamp(0, calorieProvider.targetProtein);
    final name = PrefsService.i.name.split(' ').first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final goldColor = isDark ? AppColors.kPrimaryGold : AppColors.stPrimary;
    final dividerColor = isDark ? Colors.white12 : AppColors.stOutlineVariant.withOpacity(0.3);
    final welcomeTextColor = isDark ? Colors.white70 : AppColors.stOnSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildApexPortrait(),
          const SizedBox(height: 24),
          FantasyCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🧙‍♂️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Apex, Wise Trainer',
                      style: GoogleFonts.plusJakartaSans(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Divider(color: dividerColor, height: 20),
                _buildInfoRow('⚔️ Adventurer', name),
                _buildInfoRow(
                    '🎯 Quest Target', '${calorieProvider.targetCalories} kcal'),
                _buildInfoRow(
                    '💪 Protein',
                    proteinGap > 0
                        ? '${proteinGap.toStringAsFixed(1)}g tersisa'
                        : '✅ Tercapai!'),
                const SizedBox(height: 14),
                Text(
                  'Selamat datang, Adventurer $name! 🧙‍♂️\nAku Apex, penasihat kesehatanmu. Tanyakan apapun tentang nutrisi, atau pilih salah satu quest di bawah.',
                  style: GoogleFonts.plusJakartaSans(
                    color: welcomeTextColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),
          _buildQuickQuestButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white38 : AppColors.stOnSurfaceVariant.withOpacity(0.7), fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : AppColors.stOnSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApexPortrait() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.kPrimaryGold.withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryGold.withOpacity(0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/apex_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.kDarkSurface,
              child: const Center(
                child: Text('🧙‍♂️', style: TextStyle(fontSize: 48)),
              ),
            );
          },
        ),
      ),
    )
        .animate(
            onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1.03, 1.03),
            duration: 2.seconds,
            curve: Curves.easeInOut);
  }

  // ── Quick Quest Buttons ───────────────────────────────────────────────
  Widget _buildQuickQuestButtons() {
    final quests = [
      _QuestAction(icon: '💡', label: 'Tips Harian',
          prompt: 'Berikan tips harian untuk saya hari ini.'),
      _QuestAction(icon: '🍗', label: 'Rekomendasi',
          prompt: 'Rekomendasikan makanan sehat untuk sisa kalori saya.'),
      _QuestAction(icon: '📊', label: 'Analisis Makro',
          prompt: 'Analisis progres kalori dan makro saya hari ini.'),
      _QuestAction(icon: '🏋️', label: 'Saran Latihan',
          prompt: 'Apa saran latihan untuk goal saya saat ini?'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quests.map((q) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildQuestChip(
              icon: q.icon,
              label: q.label,
              onTap: () {
                _controller.text = q.prompt;
                _sendMessage();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestChip({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryGold.withOpacity(0.08),
            border:
                Border.all(color: AppColors.kPrimaryGold.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : AppColors.stPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Row(
        children: [
          _buildApexMiniAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.kPrimaryGold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(
                  '🧙‍♂️ Apex sedang berpikir',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.kPrimaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const _TypingDot(delay: 0),
                const SizedBox(width: 2),
                const _TypingDot(delay: 200),
                const SizedBox(width: 2),
                const _TypingDot(delay: 400),
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
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.kPrimaryGold.withOpacity(0.5), width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/apex_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.kDarkSurface,
              child: const Center(
                child: Text('🧙‍♂️', style: TextStyle(fontSize: 16)),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Input Area ────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor = isDark ? Colors.white : AppColors.stOnSurface;
    final hintColor = isDark ? Colors.white30 : AppColors.stOnSurfaceVariant.withOpacity(0.5);

    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(
                color: AppColors.kPrimaryGold.withOpacity(0.15), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryGold.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.kPrimaryGold.withOpacity(0.25)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.plusJakartaSans(
                    color: inputColor, fontSize: 13.5),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu ke Apex...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      color: hintColor, fontSize: 13),
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
                color:
                    _isLoading ? Colors.white10 : AppColors.kPrimaryGold,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.kPrimaryGold.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading
                    ? Colors.white30
                    : const Color(0xFF1A1A2E),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Riwayat Chat?',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text(
            'Semua percakapan dengan Apex akan dihapus dan sesi baru akan dimulai.',
            style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────

class _QuestAction {
  final String icon;
  final String label;
  final String prompt;
  const _QuestAction(
      {required this.icon, required this.label, required this.prompt});
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
            color: AppColors.kPrimaryGold.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}