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
    final xpProgress = xpMax > xpMin ? (_xp - xpMin) / (xpMax - xpMin) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.stBackground,
      appBar: const RPGAppBar(screenKey: 'profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // px-container-margin mt-lg
        child: Column(
          children: [
            // ── 1. Profile Hero Card ─────────────────────────────────────────
            // hero-gradient rounded-xl p-md, overflow hidden, card-inner-glow
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  // Edit button — absolute top right
                  Positioned(
                    top: 0, right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar — w-20 h-20, rounded-full, border-4 primary-container
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(BorderSide(color: AppColors.stPrimaryFixed, width: 4)),
                                ),
                                child: ClipOval(
                                  child: Image.asset('assets/images/apex_avatar.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.stPrimaryFixed.withOpacity(0.3),
                                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                              // Rank badge — absolute -bottom-2 -right-2
                              Positioned(
                                bottom: -2, right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.stSecondaryContainer,
                                    borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                                    border: Border.all(color: AppColors.stOnSecondary.withOpacity(0.2)),
                                  ),
                                  child: Text('RANK ${GamificationService.getCurrentLevel(_xp)}',
                                    style: GoogleFonts.nunitoSans(fontSize: 9, fontWeight: FontWeight.w800,
                                      color: AppColors.stOnSecondary)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppColors.stSpaceLg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name — headline-lg-mobile 22px/800
                                Text(_name, style: GoogleFonts.montserrat(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 28/22)),
                                const SizedBox(height: AppColors.stSpaceXs),
                                // Badges inline
                                Wrap(
                                  spacing: 4, runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(_rank.toUpperCase() + ' WARRIOR',
                                        style: GoogleFonts.nunitoSans(fontSize: 9, fontWeight: FontWeight.w800,
                                          letterSpacing: 1, color: AppColors.stPrimaryFixed)),
                                    ),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Text('🔥', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 2),
                                      Text('$_workoutStreak Hari Streak',
                                        style: GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // XP Bar
                      Padding(
                        padding: const EdgeInsets.only(top: AppColors.stSpaceMd),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('XP Progress', style: GoogleFonts.nunitoSans(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
                                Text('${_xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]}.')}'
                                  ' / ${xpMax.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]}.')}',
                                  style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 8, // h-2
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: xpProgress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [AppColors.stPrimaryFixed, AppColors.stPrimaryContainer]),
                                    ),
                                    child: Container(color: Colors.white.withOpacity(0.2)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),

            // ── 2. Stat Tubuh ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer,
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.monitoring_rounded, label: 'STAT TUBUH', isDark: isDark),
                  const SizedBox(height: AppColors.stSpaceMd),
                  Row(
                    children: [
                      Expanded(child: _StatCell(label: 'BERAT', value: '${_weight.toInt()}', unit: 'kg', isDark: isDark)),
                      const SizedBox(width: AppColors.stSpaceSm),
                      Expanded(child: _StatCell(label: 'TINGGI', value: '${_height.toInt()}', unit: 'cm', isDark: isDark)),
                      const SizedBox(width: AppColors.stSpaceSm),
                      Expanded(child: _StatCell(label: 'BMI', value: bmiStr, unit: bmiLabel,
                        valueColor: bmiColor, unitBg: bmiBg, unitColor: bmiColor, isDark: isDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),

            // ── 3. Mode Tujuan ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer,
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.my_location_rounded, label: 'MODE TUJUAN', isDark: isDark),
                  const SizedBox(height: AppColors.stSpaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppColors.stSpaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.stPrimaryContainer.withOpacity(0.1),
                      border: Border.all(color: AppColors.stPrimaryContainer.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('$goalEmoji ${_goal.toUpperCase()}',
                            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary)),
                          Text('Target: ${targetCal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]}.')} kcal/hari',
                            style: GoogleFonts.inter(fontSize: 14,
                              color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary,
                            borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                          ),
                          child: Text('AKTIF', style: GoogleFonts.nunitoSans(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.stOnPrimaryFixed : AppColors.stOnPrimary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),

            // ── 4. Rekomendasi AI ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                border: Border.all(color: AppColors.stPrimaryContainer.withOpacity(0.5), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Icon(Icons.psychology_rounded, color: AppColors.stSecondary, size: 20),
                      const SizedBox(width: AppColors.stSpaceSm),
                      Text('REKOMENDASI AI', style: GoogleFonts.nunitoSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
                        letterSpacing: 1)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.stOnTertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Fuzzy Logic v4.2', style: GoogleFonts.inter(
                        fontSize: 10, fontStyle: FontStyle.italic,
                        color: AppColors.stTertiaryFixed)),
                    ),
                  ]),
                  const SizedBox(height: AppColors.stSpaceMd),
                  // Inner white card
                  Container(
                    padding: const EdgeInsets.all(AppColors.stSpaceMd),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurface,
                      borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
                      border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${targetCal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]}.')} kcal/hari',
                          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary)),
                        Row(children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.stSecondary, size: 16),
                          const SizedBox(width: 4),
                          Text('SESUAI', style: GoogleFonts.nunitoSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.stSecondary)),
                        ]),
                      ]),
                      const SizedBox(height: AppColors.stSpaceSm),
                      // 4 tags — surface-container bg
                      GridView.count(
                        crossAxisCount: 2, shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8, mainAxisSpacing: 8,
                        childAspectRatio: 3.5,
                        children: [
                          _InfoTag(icon: Icons.monitor_heart_rounded, label: 'BMI: Normal', isDark: isDark),
                          _InfoTag(icon: Icons.directions_run_rounded, label: 'Aktivitas: $_activityLevel', isDark: isDark),
                          _InfoTag(icon: Icons.flag_rounded, label: 'Tujuan: $_goal', isDark: isDark),
                          _InfoTag(icon: Icons.cake_rounded, label: 'Usia: $_age Tahun', isDark: isDark),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppColors.stSpaceMd),
                  // Konsultasi Apex button — hero-gradient
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3))),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppColors.stSpaceMd),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0,4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: AppColors.stSpaceMd),
                          Text('KONSULTASI APEX', style: GoogleFonts.montserrat(
                            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),

            // ── 5. Pengaturan ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer,
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENGATURAN', style: GoogleFonts.nunitoSans(
                    fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1,
                    color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant)),
                  const SizedBox(height: AppColors.stSpaceMd),

                  // Notifikasi — Switch (dipertahankan)
                  _SettingsSwitch(
                    icon: Icons.notifications_rounded, label: 'Notifikasi',
                    value: _notificationsEnabled, isDark: isDark,
                    onChanged: (val) async {
                      setState(() => _notificationsEnabled = val);
                      await PrefsService.i.setNotificationsEnabled(val);
                      if (val) await SmartNotificationService.refreshAndReschedule();
                      else await SmartNotificationService.cancelAll();
                    },
                  ),

                  // Dark Mode — Switch (dipertahankan)
                  _SettingsSwitch(
                    icon: Icons.dark_mode_rounded, label: 'Tema Gelap',
                    value: themeProvider.isDark, isDark: isDark,
                    onChanged: (val) => themeProvider.setDark(val),
                  ),

                  // Item chevron
                  _SettingsChevron(icon: Icons.translate_rounded, label: 'Bahasa', trailing: 'Indonesia', isDark: isDark),
                  _SettingsChevron(icon: Icons.download_rounded, label: 'Export Data', isDark: isDark,
                    onTap: () => BackupService.exportDataAsJson(context)),
                  _SettingsChevron(icon: Icons.info_rounded, label: 'Tentang', isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),

            // ── Logout ───────────────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                final prefs = PrefsService.i.raw;
                await prefs.clear();
                if (mounted) Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppColors.stSpaceMd),
                child: Center(child: Text('Keluar dari Petualangan',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.stError))),
              ),
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
// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _SectionHeader({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.stPrimary, size: 20),
        const SizedBox(width: AppColors.stSpaceSm),
        Text(label, style: GoogleFonts.nunitoSans(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1,
          color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant)),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value, unit;
  final Color? valueColor, unitBg, unitColor;
  final bool isDark;

  const _StatCell({
    required this.label, required this.value, required this.unit,
    required this.isDark, this.valueColor, this.unitBg, this.unitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceSm),
      decoration: BoxDecoration(
        // bg-background = surface-container-lowest (putih)
        color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
        border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: GoogleFonts.nunitoSans(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: valueColor ?? (isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: unitBg ?? Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
          ),
          child: Text(unit, style: GoogleFonts.nunitoSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: unitColor ?? (isDark ? AppColors.kDarkTextSub : AppColors.stOutline))),
        ),
      ]),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoTag({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainer,
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.stOutline),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon, required this.label,
    required this.value, required this.isDark, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.stSpaceSm),
      child: Row(children: [
        // icon circle — primary-container/20
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.stPrimaryContainer.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.stPrimary),
        ),
        const SizedBox(width: AppColors.stSpaceMd),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _SettingsChevron extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsChevron({
    required this.icon, required this.label, required this.isDark,
    this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppColors.stSpaceSm),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.stPrimaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.stPrimary),
          ),
          const SizedBox(width: AppColors.stSpaceMd),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
          if (trailing != null) ...[
            Text(trailing!, style: GoogleFonts.inter(
              fontSize: 12, color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline)),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right_rounded,
            color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline, size: 20),
        ]),
      ),
    );
  }
}
