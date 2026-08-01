import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';
import 'package:provider/provider.dart';
import '../models/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calorie_provider.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../utils/app_snackbar.dart';
import '../widgets/fantasy_card.dart';
import '../widgets/profile_settings_widgets.dart';
import '../widgets/profile_hero_card.dart';
import '../widgets/calorie_calculation_detail_modal.dart';
import '../widgets/weekly_insight_card.dart';
import 'main_screen.dart';
import '../services/smart_notification_service.dart';
import '../services/backup_service.dart';
import '../services/gamification_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileComplete;
  
  const ProfileScreen({super.key, this.onProfileComplete});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _hasProfile = false;
  bool _isEditing = false;
  
  // Data profil
  String _name = '';
  int _age = 0;
  double _weight = 0;
  double _height = 0;
  String _gender = 'Pria';
  String _activityLevel = 'Sedang';
  String _goal = 'Bulking';
  bool _notificationsEnabled = false;
  
  // Gamifikasi Data
  int _xp = 0;
  String _rank = 'Bronze';

  int _workoutStreak = 0;
  int _activeDays = 1;

  // Controller
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final prefs = PrefsService.i.raw;
    final gamification = GamificationService();
    final stats = await gamification.getUserStats();
    
    setState(() {
      _hasProfile = prefs.getBool('has_profile') ?? false;
      _isEditing = !_hasProfile; // Langsung edit jika belum punya profil
      
      _name = prefs.getString('name') ?? 'Pengguna Baru';
      _age = prefs.getInt('age') ?? 0;
      _weight = prefs.getDouble('weight') ?? 0;
      _height = prefs.getDouble('height') ?? 0;
      _gender = prefs.getString('gender') ?? 'Pria';
      _activityLevel = prefs.getString('activity_level') ?? 'Sedang';
      _goal = prefs.getString('goal') ?? 'Bulking';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      _xp = stats['xp'];
      _rank = stats['rank'];
      
      _workoutStreak = prefs.getInt('workout_streak') ?? 0;
      _activeDays = prefs.getInt('app_open_count') ?? 1;
      if (_activeDays < 1) _activeDays = 1;
      
      _nameController.text = _name;
      _ageController.text = _age > 0 ? _age.toString() : '';
      _weightController.text = _weight > 0 ? _weight.toString() : '';
      _heightController.text = _height > 0 ? _height.toString() : '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return _isEditing ? _buildForm() : _buildDashboard();
  }
  
  // ================= DASHBOARD UI =================
  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    // Hitung BMI
    final bmi = _height > 0 ? _weight / ((_height / 100) * (_height / 100)) : 0.0;
    final bmiStr = bmi > 0 ? bmi.toStringAsFixed(1) : '--';
    String bmiLabel = 'NORMAL';
    Color bmiColor = AppColors.stTertiary;
    Color bmiBg = AppColors.stTertiaryContainer.withOpacity(0.2);
    if (bmi > 0) {
      if (bmi < 18.5) { bmiLabel = 'KURUS'; bmiColor = AppColors.stPrimary; bmiBg = AppColors.stPrimaryContainer.withOpacity(0.2); }
      else if (bmi >= 25) { bmiLabel = 'GEMUK'; bmiColor = AppColors.stError; bmiBg = AppColors.stErrorContainer.withOpacity(0.3); }
    }

    // Target kalori untuk display (pakai CalorieProvider jika tersedia)
    final targetCal = context.watch<CalorieProvider>().targetCalories;
    final goalEmoji = switch (_goal) {
      'Bulking' => '💪', 'Cutting' => '✂️', _ => '⚖️',
    };

    // XP progress dalam rank saat ini
    final gamification = GamificationService();
    final rankProgress = gamification.getRankProgress(_xp);
    final xpMin = rankProgress['min_xp']!;
    final xpMax = rankProgress['max_xp']!;
    final rankTheme = RankTheme.fromRank(_rank);

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.stBackground,
      appBar: const RPGAppBar(screenKey: 'profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // px-container-margin mt-lg
        child: Column(
          children: [
            // ── 1. Profile Hero Card ─────────────────────────────────────────
            ProfileHeroCard(
              name: _name,
              xp: _xp,
              rank: _rank,
              workoutStreak: _workoutStreak,
              onEditPressed: () => setState(() => _isEditing = true),
              weight: _weight,
              height: _height,
              bmiStr: bmiStr,
              bmiLabel: bmiLabel,
              bmiColor: bmiColor,
              bmiBg: bmiBg,
              goal: _goal,
              targetCal: targetCal,
              goalEmoji: goalEmoji,
              activityLevel: _activityLevel,
              age: _age,
            ),
            const SizedBox(height: 16),
            _buildFuzzyLogicCard(rankTheme),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: rankTheme.borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: rankTheme.glowColor,
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const WeeklyInsightCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuzzyLogicCard(RankTheme rankTheme) {
    return GestureDetector(
      onTap: () {
        CalorieCalculationDetailModal.show(
          context,
          name: _name,
          age: _age,
          weight: _weight,
          height: _height,
          gender: _gender,
          activityLevel: _activityLevel,
          goal: _goal,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              rankTheme.gradientColors[0].withOpacity(0.85),
              rankTheme.gradientColors[1].withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rankTheme.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: rankTheme.glowColor,
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fuzzy Logic Engine v4.2',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat detail formula & kalkulasi kalori harianmu.',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.stBackground,
      appBar: AppBar(
        title: Text(_hasProfile ? 'EDIT PROFILE' : 'CREATE PROFILE', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _hasProfile 
          ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.black87), onPressed: () => setState(() => _isEditing = false))
          : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FantasyCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      decoration: _buildInputDecoration('Nama Hero', Icons.person_rounded),
                      validator: (val) => (val == null || val.isEmpty) ? 'Nama wajib diisi' : null,
                      onSaved: (val) => _name = val ?? '',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            decoration: _buildInputDecoration('Usia', Icons.calendar_today_rounded),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _age = int.tryParse(val!) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _buildInputDecoration('Gender', Icons.wc_rounded),
                            value: _gender,
                            items: ['Pria', 'Wanita'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) => setState(() => _gender = val ?? 'Pria'),
                            onSaved: (val) => _gender = val ?? 'Pria',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            decoration: _buildInputDecoration('Berat (kg)', Icons.monitor_weight_rounded),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => _weight = double.tryParse(val!) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            decoration: _buildInputDecoration('Tinggi (cm)', Icons.height_rounded),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => _height = double.tryParse(val!) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _buildInputDecoration('Aktivitas', Icons.directions_run_rounded),
                      value: _activityLevel,
                      items: ['Ringan', 'Sedang', 'Berat', 'Sangat Berat'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _activityLevel = val!),
                      onSaved: (val) => _activityLevel = val!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _buildInputDecoration('Goal Fitness', Icons.emoji_events_rounded),
                      value: _goal,
                      items: ['Bulking', 'Cutting', 'Maintenance'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _goal = val!),
                      onSaved: (val) => _goal = val!,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('SIMPAN PROFIL'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(num val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: AppColors.kPrimaryOrange, size: 20),
      filled: true,
      fillColor: AppColors.stInputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppColors.stRadiusLg), borderSide: const BorderSide(color: AppColors.stPrimary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final prefs = PrefsService.i.raw;
      await prefs.setBool('has_profile', true);
      await prefs.setString('name', _name);
      await prefs.setInt('age', _age);
      await prefs.setDouble('weight', _weight);
      await prefs.setDouble('height', _height);
      await prefs.setString('gender', _gender);
      await prefs.setString('activity_level', _activityLevel);
      await prefs.setString('goal', _goal);
      
      if (context.mounted) {
        await context.read<CalorieProvider>().calculateTargets();
        setState(() {
          _hasProfile = true;
          _isEditing = false;
        });
        
        AppSnackbar.success(context, 'Profil berhasil disimpan!');
        
        if (widget.onProfileComplete != null) {
          widget.onProfileComplete!();
        } else if (Navigator.canPop(context) == false) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)));
        }
      }
    }
  }
}

