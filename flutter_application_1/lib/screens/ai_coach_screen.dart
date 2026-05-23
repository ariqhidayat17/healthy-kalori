import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/groq_service.dart';
import '../models/calorie_provider.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final GroqService _groqService = GroqService();
  final ScrollController _scrollController = ScrollController();

  // Pesan yang ditampilkan di UI (tidak termasuk system prompt)
  final List<Map<String, String>> _displayMessages = [];

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
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User';
    final age = prefs.getInt('age') ?? 0;
    final weight = prefs.getDouble('weight') ?? 0.0;
    final height = prefs.getDouble('height') ?? 0.0;
    final gender = prefs.getString('gender') ?? 'Pria';
    final activityLevel = prefs.getString('activity_level') ?? 'Sedang';
    final goal = prefs.getString('goal') ?? 'Bulking';

    // Bangun system prompt (selalu paling awal, tidak ditampilkan di UI)
    final systemPrompt = {
      'role': 'system',
      'content': '''Kamu adalah AI Coach khusus kesehatan, nutrisi, dan kebugaran (bodybuilding) profesional berbahasa Indonesia.
Profil user: Nama: $name | Umur: $age tahun | Berat: $weight kg | Tinggi: $height cm | Gender: $gender | Target: $goal.

INFO APLIKASI (PENTING):
Beri tahu user bahwa aplikasi "Your AI Coach" ini memiliki fitur berikut jika relevan dengan pertanyaan mereka:
- Tombol '+' (Kanan Bawah di Layar Tracker): Untuk mencari database makanan manual.
- Kamera AI (Ikon Kamera Biru): Untuk foto makanan dan AI akan otomatis menghitung kalori & nutrisinya.
- Barcode Scanner (Ikon Barcode Emas): Untuk scan barcode produk kemasan agar datanya langsung terisi.
- Water Tracker & Workout Logger: Tersedia di layar Utama (Home).
- Progress Photo: Tersedia di halaman Profil untuk membandingkan foto bentuk fisik (Before/After).

CARA KERJA APLIKASI INI (TEKNIS - Jawab jika ditanya):
Jika pengguna (atau dosen penguji) bertanya bagaimana aplikasi ini dibuat atau bekerja, jelaskan dengan bangga:
1. Analisis AI Kamera: Menggunakan "Groq Vision API" (Model LLaMA 3.2 Vision) untuk memproses gambar Base64 menjadi data JSON berisi estimasi porsi, kalori, dan makro.
2. Barcode Scanner: Terhubung dengan RESTful API dari "OpenFoodFacts" secara real-time untuk menarik data gizi produk kemasan dunia.
3. Database: Menggunakan "SQLite" sebagai penyimpanan lokal (offline-first) untuk performa cepat dan privasi data.
4. Perhitungan Kalori: Menggunakan algoritma TDEE dinamis yang bereaksi terhadap perubahan log berat badan pengguna.
5. Pembuat Aplikasi: Dibuat menggunakan framework "Flutter" dengan arsitektur State Management "Provider".

ATURAN WAJIB dalam SETIAP respons:
1. Berikan saran yang spesifik, ilmiah, dan praktis dengan bahasa yang asik, ramah, dan profesional.
2. JIKA RELEVAN, ajak user menggunakan fitur aplikasi ini (seperti Kamera AI atau Barcode Scanner).
3. SETIAP saran atau klaim ilmiah HARUS disertai referensi dari sumber terpercaya (WHO, ACSM, dsb).
4. Format referensi menggunakan blockquote markdown (>).
5. Tambahkan disclaimer singkat jika saran bersifat medis.
6. Gunakan format Markdown yang rapi: heading, bold, bullet list.''',
    };

    _apiMessages.add(systemPrompt);

    // Coba muat riwayat percakapan dari SharedPreferences
    final savedHistory = prefs.getString(_prefsKey);
    if (savedHistory != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedHistory);
        final history = decoded.cast<Map<String, dynamic>>().map((m) {
          return {'role': m['role'] as String, 'content': m['content'] as String};
        }).toList();

        // Tambahkan riwayat ke API messages dan display messages
        _apiMessages.addAll(history);
        _displayMessages.addAll(history);
      } catch (_) {
        // Jika parsing gagal, mulai sesi baru dengan sapaan
        _addWelcomeMessage(name, goal, prefs);
      }
    } else {
      // Sesi pertama — tampilkan sapaan
      _addWelcomeMessage(name, goal, prefs);
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _scrollToBottom();
    }
  }

  void _addWelcomeMessage(String name, String goal, SharedPreferences prefs) {
    final welcome = {
      'role': 'assistant',
      'content': 'Halo $name! 👋 Saya AI Coach kamu. Ada yang bisa saya bantu soal target **$goal** kamu hari ini?',
    };
    _apiMessages.add(welcome);
    _displayMessages.add(welcome);
    _saveHistory();
  }

  // Simpan riwayat percakapan (hanya display messages) ke SharedPreferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Simpan hanya pesan yang muncul di UI (bukan system prompt)
    await prefs.setString(_prefsKey, jsonEncode(_displayMessages));
  }

  // Hapus riwayat percakapan dan mulai ulang
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    final name = prefs.getString('name') ?? 'User';
    final goal = prefs.getString('goal') ?? 'Bulking';

    setState(() {
      _displayMessages.clear();
      // Pertahankan system prompt di API messages; hapus sisanya
      _apiMessages.removeWhere((m) => m['role'] != 'system');
    });

    _addWelcomeMessage(name, goal, prefs);
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Beri delay singkat agar widget selesai di-render dulu
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    final calorieProvider = context.read<CalorieProvider>();
    final prefs = await SharedPreferences.getInstance();

    final lastWorkout = prefs.getString('last_workout_date') ?? 'Belum ada';
    final streak = prefs.getInt('workout_streak') ?? 0;

    // Pesan user yang ditampilkan di UI (tanpa stats konteks)
    final userDisplayMsg = {'role': 'user', 'content': text};

    // Pesan yang dikirim ke API (dengan konteks real-time)
    final contextSuffix =
        '\n\n*(Konteks real-time: Kalori hari ini ${calorieProvider.totalConsumedCalories} kkal | '
        'Protein: ${calorieProvider.totalConsumedProtein}g | '
        'Karbo: ${calorieProvider.totalConsumedCarbs}g | '
        'Lemak: ${calorieProvider.totalConsumedFats}g | '
        'Air: ${calorieProvider.totalConsumedWater}ml | '
        'Latihan terakhir: $lastWorkout | Streak: $streak hari)*';

    final userApiMsg = {'role': 'user', 'content': '$text$contextSuffix'};

    setState(() {
      _displayMessages.add(userDisplayMsg);
      _apiMessages.add(userApiMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    // Kirim ke API menggunakan API messages (dengan konteks)
    final response = await _groqService.getChatResponse(_apiMessages);

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
      appBar: AppBar(
        title: const Text('AI Coach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Hapus Riwayat Chat',
            onPressed: _showClearHistoryDialog,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
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
                              return _buildMessageBubble(msg['content']!, isUser);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.1),
            ),
            child: const Icon(Icons.smart_toy, size: 48, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tanya apapun soal diet,\nlatihan, atau nutrisi kamu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFBBAA88), fontSize: 15),
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
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFD4AF37),
            child: Icon(Icons.smart_toy, size: 16, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
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

  Widget _buildMessageBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFD4AF37),
              child: Icon(Icons.smart_toy, size: 18, color: Color(0xFF111111)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isUser
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.05),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: isUser
                  ? Text(
                      content,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : MarkdownBody(
                      data: content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            color: Color(0xFFF0E6C8),
                            fontSize: 15,
                            height: 1.5),
                        listBullet: const TextStyle(
                            color: Color(0xFFD4AF37), fontSize: 15),
                        strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37)),
                        h1: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                        h2: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 17),
                        h3: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        blockquote: const TextStyle(
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                            fontSize: 13),
                        blockquoteDecoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(
                                  color: Color(0xFFD4AF37), width: 3)),
                        ),
                        listIndent: 20,
                        blockSpacing: 12,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2A2A2A),
              child:
                  Icon(Icons.person, size: 18, color: Color(0xFFD4AF37)),
            ),
          ],
        ],
      ),
    );
  }

  final List<String> _allQuestions = [
    "Menu sarapan tinggi protein praktis?",
    "Bagaimana memecah plateau berat badan?",
    "Bolehkah latihan beban setiap hari?",
    "Tips penuhi protein tanpa suplemen",
    "Bedanya bulking kotor dan bersih?",
    "Berapa banyak air yang harus saya minum?",
    "Cara mengurangi lemak perut membandel?",
    "Olahraga terbaik untuk cutting?",
    "Apakah suplemen BCAA itu perlu?",
    "Waktu terbaik untuk kardio?",
  ];
  late List<String> _suggestedQuestions;

  Widget _buildSuggestedQuestions() {
    if (_isLoading) return const SizedBox.shrink(); // Sembunyikan saat AI sedang mengetik
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: const Color(0xFF1A1A1A),
              side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
              label: Text(_suggestedQuestions[index], style: const TextStyle(color: Color(0xFFF0E6C8), fontSize: 13)),
              onPressed: () {
                _controller.text = _suggestedQuestions[index];
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Column(
        children: [
          _buildSuggestedQuestions(),
          if (!_isLoading) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                    color: Color(0xFFF0E6C8), fontSize: 15),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Tanya coach...',
                  hintStyle: TextStyle(color: Color(0xFF665C44)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isLoading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFCD7F32), Color(0xFFFFD700)]),
              color: _isLoading ? const Color(0xFF2A2A2A) : null,
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _isLoading
                    ? const Color(0xFF555555)
                    : const Color(0xFF111111),
                size: 22,
              ),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
              ],
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
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text(
            'Semua percakapan dengan AI Coach akan dihapus dan sesi baru akan dimulai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
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
            color: const Color(0xFFD4AF37).withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
