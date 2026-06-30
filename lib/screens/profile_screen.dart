import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';
import 'package:provider/provider.dart';
import '../models/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/calorie_provider.dart';
import '../models/fuzzy_logic.dart';
import '../models/user_profile.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../utils/app_snackbar.dart';
import '../widgets/fantasy_card.dart';
import '../widgets/fantasy_rank_badge.dart';
import 'main_screen.dart';
import '../utils/notification_helper.dart';
import '../services/smart_notification_service.dart';
import 'progress_photo_screen.dart';
import 'weight_log_screen.dart';
import 'stats_screen.dart';
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
    double bmi = 0;
    if (_height > 0) {
      bmi = _weight / ((_height / 100) * (_height / 100));
    }
    String bmiStatus = 'Normal';
    if (bmi < 18.5) bmiStatus = 'Underweight';
    else if (bmi >= 25) bmiStatus = 'Overweight';

    return Scaffold(
      backgroundColor: AppColors.kBgCream,
      appBar: RPGAppBar(screenKey: 'profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header: Hero Stats
            FantasyCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FantasyRankBadge(
                    rankName: _rank,
                    level: GamificationService.getCurrentLevel(_xp),
                    progress: 0.5, // Placeholder
                    size: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name.toUpperCase(), 
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.kHealthRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('🔥 $_workoutStreak Hari Streak', style: GoogleFonts.nunito(color: AppColors.kHealthRed, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 24),

            // Body Stats
            _sectionTitle('STATISTIK TUBUH'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('$_weight kg', 'Berat'),
                const SizedBox(width: 12),
                _buildStatItem('$_height cm', 'Tinggi'),
                const SizedBox(width: 12),
                _buildStatItem(bmi.toStringAsFixed(1), bmiStatus),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Goal Mode
            _sectionTitle('MODE TUJUAN'),
            const SizedBox(height: 12),
            FantasyCard(
              padding: const EdgeInsets.all(20),
              gradient: const LinearGradient(colors: [Color(0x1AFF8C42), Color(0x1AFFB800), Color(0x1AFFD93D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              child: Row(
                children: [
                  const Text('💪', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_goal.toUpperCase()} (Aktif)',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.kPrimaryOrange),
                        ),
                        Text(
                          'Target: ${context.watch<CalorieProvider>().targetCalories} kcal / hari',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.kPrimaryOrange, size: 16),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // AI Recommendations (Fuzzy Logic)
            _sectionTitle('REKOMENDASI AI (FUZZY LOGIC)'),
            const SizedBox(height: 12),
            FantasyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🧮', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        '${context.watch<CalorieProvider>().targetCalories} kcal / hari',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.kNatureGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('✅ SESUAI', style: GoogleFonts.nunito(color: AppColors.kNatureGreen, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildFuzzyDetail('BMI', bmi.toStringAsFixed(1), bmiStatus),
                  _buildFuzzyDetail('Aktivitas', _activityLevel, 'Normal'),
                  _buildFuzzyDetail('Tujuan', _goal, 'Optimal'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 5)),
                        );
                      },
                      icon: const Icon(Icons.smart_toy_rounded, size: 18),
                      label: const Text('KONSULTASI APEX'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryGold),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Settings
            _sectionTitle('PENGATURAN'),
            const SizedBox(height: 12),
            _buildSettingsList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: FantasyCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildFuzzyDetail(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $label: $value', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          Text('($status)', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppColors.kDarkSoftShadow
            : AppColors.kSoftShadow,
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.notifications_active_rounded,
            'Notifikasi',
            'Reminder personal berbasis data',
            AppColors.kPrimaryOrange,
            _notificationsEnabled,
            (val) async {
              setState(() => _notificationsEnabled = val);
              await PrefsService.i.setNotificationsEnabled(val);
              if (val) {
                await SmartNotificationService.refreshAndReschedule();
              } else {
                await SmartNotificationService.cancelAll();
              }
            },
          ),
          _divider(),
          _buildSettingsTile(
            Icons.dark_mode_rounded,
            'Dark Mode',
            'Tampilan gelap hemat baterai',
            AppColors.kMysticPurple,
            themeProvider.isDark,
            (val) => themeProvider.setDark(val),
          ),
          _divider(),
          _buildActionTile(Icons.backup_rounded, 'Cadangkan Data', 'Ekspor ke format JSON', Colors.green, () => BackupService.exportDataAsJson(context)),
          _divider(),
          _buildActionTile(Icons.logout_rounded, 'Keluar', 'Sesi akan diakhiri', Colors.red, () {}),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 64, color: Colors.grey[100]);

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, Color color, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: color),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color == Colors.red ? Colors.red : Colors.black87)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  // ================= FORM UI =================
  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.kBgCream,
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: AppColors.kPrimaryOrange, size: 20),
      filled: true,
      fillColor: AppColors.kBgCream,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimaryOrange, width: 1.5)),
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