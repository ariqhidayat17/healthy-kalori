import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tombol opsi tambah makanan (Manual / AI Scan / Barcode / dll)
/// di bottom sheet CalorieTrackerScreen.
class AddFoodOptionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  /// Jika true, otomatis pop bottom sheet sebelum memanggil [onTap].
  final bool popOnTap;

  const AddFoodOptionButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.popOnTap = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (popOnTap) Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
