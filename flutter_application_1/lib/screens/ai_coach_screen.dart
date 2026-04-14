import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
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
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSystemPrompt();
  }

  Future<void> _initSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User';
    final age = prefs.getInt('age') ?? 0;
    final weight = prefs.getDouble('weight') ?? 0.0;
    final height = prefs.getDouble('height') ?? 0.0;
    final gender = prefs.getString('gender') ?? 'Pria';
    final activityLevel = prefs.getString('activity_level') ?? 'Sedang';
    final goal = prefs.getString('goal') ?? 'Bulking';
    
    // Provide general context to system (hidden from UI)
    _messages.add({
      "role": "system",
      "content": "Kamu adalah AI Coach khusus binaraga (bodybuilding) profesional. "
          "Nama user: $name, Umur: $age, Berat: $weight kg, Tinggi: $height cm, Gender: $gender, Target: $goal. "
          "Berikan saran yang sangat spesifik, ilmiah, dan berikan porsi/saran otot dengan bahasa Indonesia yang asik, ramah profesional."
    });

    setState(() {
      _messages.add({
        "role": "assistant",
        "content": "Halo $name! Saya AI Coach kamu. Ada yang bisa saya bantu soal target $goal kamu hari ini?",
      });
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final calorieProvider = context.read<CalorieProvider>();
    // Menambahkan konteks tambahan pada pesan pengguna ke AI (tersembunyi dari UI)
    final promptWithStats = "$text\n(Konteks: Hari ini user sudah mengonsumsi ${calorieProvider.totalConsumedCalories} kkal, ${calorieProvider.totalConsumedProtein}g protein, ${calorieProvider.totalConsumedCarbs}g karbo, dan ${calorieProvider.totalConsumedFats}g lemak.)";

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });

    // Salin pesan yang akan dikirim ke API
    final apiMessages = List<Map<String, String>>.from(_messages);
    
    // Ganti indeks terakhir (pesan user aslinya) dengan pesan + stats
    apiMessages.removeLast();
    apiMessages.add({"role": "user", "content": promptWithStats});

    final response = await _groqService.getChatResponse(apiMessages);

    setState(() {
      // Hilangkan tag/notes dari bot di UI jika AI memberikannya secara sadar
      _messages.add({"role": "assistant", "content": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sembunyikan prompt sistem agar tidak muncul di daftar obrolan
    final displayMessages = _messages.where((m) => m['role'] != 'system').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final isUser = displayMessages[index]['role'] == 'user';
                return _buildMessageBubble(displayMessages[index]['content']!, isUser);
              },
            ),
          ),
          if (_isLoading) 
             const Padding(
               padding: EdgeInsets.all(8.0), 
               child: CircularProgressIndicator()
             ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? const Color(0xFF0D0D0D) : const Color(0xFFF0E6C8),
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 8.0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2E2A1E), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Color(0xFFF0E6C8)),
                decoration: const InputDecoration(
                  hintText: 'Tanya coach...',
                  hintStyle: TextStyle(color: Color(0xFF665C44)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37),
            child: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF0D0D0D)),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
