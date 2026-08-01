import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../utils/prefs_service.dart';

class AdventurerGuideCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const AdventurerGuideCard({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        border: Border.all(color: AppColors.stSecondary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🧙‍♂️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR AI COACH',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: () async {
                  onDismiss();
                  await PrefsService.i.raw.setBool('hide_adventurer_guide', true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat datang di Guild Healthy Calories! Sebagai seorang Binaragawan, misi Anda adalah menjaga surplus/defisit nutrisi agar performa tubuh maksimal. Berikut adalah panduan singkat fitur utama Anda:',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideItem('📊', 'Dashboard Stat', 'Monitor sisa kalori harian dan sisa protein secara real-time di bagian atas.', isDark),
          const SizedBox(height: 8),
          _buildGuideItem('🎯', 'Quest Harian', 'Selesaikan misi konsumsi protein, kalori, dan air untuk mendapatkan Bonus XP.', isDark),
          const SizedBox(height: 8),
          _buildGuideItem('🧠', 'AI Coach Apex', 'Bicaralah dengan Apex di menu chat untuk berkonsultasi seputar menu makanan Anda.', isDark),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String emoji, String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
