import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const SaveButton({super.key, required this.onTap});

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? [const BoxShadow(color: Color(0xFF9B4500), offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: Color(0xFF9B4500), offset: Offset(0, 4)),
                  BoxShadow(color: const Color(0xFFFC8A40).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 16),
                Text(
                  'SIMPAN KE LOG',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const FieldLabel(this.text, this.isDark, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
      ),
    );
  }
}

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool isNumber;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDark,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.kDarkBorder : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.kDarkText : const Color(0xFF211B11),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class RoundStepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundStepperBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.stPrimaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.stOnPrimaryContainer, size: 22),
      ),
    );
  }
}

class CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLoading;

  const CircleIconBtn({
    super.key,
    required this.icon,
    required this.bg,
    this.iconColor = Colors.white,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
              )
            : Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
