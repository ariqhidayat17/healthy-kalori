import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';
import '../models/user_profile.dart';

class CalorieCalculationDetailModal extends StatelessWidget {
  final String name;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String activityLevel;
  final String goal;

  const CalorieCalculationDetailModal({
    super.key,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });

  static void show(
    BuildContext context, {
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CalorieCalculationDetailModal(
        name: name,
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final profile = UserProfile(
      name: name,
      age: age,
      weight: weight,
      height: height,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
    );
    final bmr = profile.calculateBMR();
    final factor = profile.getActivityFactor();
    final tdee = bmr * factor;
    final target = context.watch<CalorieProvider>().targetCalories;
    final fuzzyAdjust = target - tdee.round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkBg : AppColors.stBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppColors.stRadiusXl),
          topRight: Radius.circular(AppColors.stRadiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AppColors.stSpaceMd),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.stSecondary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Bagaimana Target Dihitung?',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AI menghitung kebutuhan kalori Anda dengan menggabungkan formula medis standar dengan kecerdasan Fuzzy Logic.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: BMR
            _buildCalcStep(
              stepNum: '1',
              title: 'Basal Metabolic Rate (BMR)',
              formula: gender == 'Pria'
                  ? 'Rumus Mifflin-St Jeor (Pria):\n(10 x Berat) + (6.25 x Tinggi) - (5 x Usia) + 5'
                  : 'Rumus Mifflin-St Jeor (Wanita):\n(10 x Berat) + (6.25 x Tinggi) - (5 x Usia) - 161',
              inputs: 'Profil: $gender, ${weight.toInt()} kg, ${height.toInt()} cm, $age tahun',
              result: '${bmr.round()} kcal',
              description: 'Energi minimum yang dibutuhkan tubuh Anda untuk bertahan hidup jika Anda beristirahat seharian penuh.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Step 2: TDEE
            _buildCalcStep(
              stepNum: '2',
              title: 'Total Daily Energy Expenditure (TDEE)',
              formula: 'Rumus: BMR x Faktor Aktivitas',
              inputs: 'Aktivitas: $activityLevel (Pengali: x$factor)',
              result: '${tdee.round()} kcal',
              description: 'Perkiraan total energi yang Anda bakar per hari setelah menghitung seluruh aktivitas fisik Anda.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Step 3: Fuzzy Adjustment
            _buildCalcStep(
              stepNum: '3',
              title: 'Penyesuaian Cerdas Fuzzy Logic',
              formula: 'Berdasarkan status BMI & tujuan fitnes Anda ($goal)',
              inputs: 'Penyesuaian surplus/defisit kalori secara bertahap',
              result: '${fuzzyAdjust >= 0 ? '+' : ''}$fuzzyAdjust kcal',
              description: 'AI menyesuaikan target kalori agar Anda mencapai target $goal tanpa memangkas energi di bawah batas aman (BMR) Anda.',
              isDark: isDark,
            ),
            const Divider(height: 32),

            // Total Target Calorie Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppColors.stRadiusLg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET HARIAN ANDA',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$target kcal',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcStep({
    required String stepNum,
    required String title,
    required String formula,
    required String inputs,
    required String result,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.stRadiusLg),
        border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.stPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNum,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkBg : AppColors.stSurfaceContainer,
              borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inputs,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hasil:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                      ),
                    ),
                    Text(
                      result,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.stPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}