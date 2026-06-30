import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Tombol utama app — konsisten di semua screen.
/// Menggantikan ElevatedButton yang tersebar dengan berbagai style berbeda.
///
/// Variants:
///   AppButton.primary   — background oranye (CTA utama)
///   AppButton.secondary — outlined oranye
///   AppButton.danger    — background merah (hapus/logout)
///   AppButton.ghost     — transparan dengan text oranye
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final _ButtonVariant _variant;

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  }) : _variant = _ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  }) : _variant = _ButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : _variant = _ButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : _variant = _ButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  Color get _bgColor => switch (widget._variant) {
        _ButtonVariant.primary   => AppColors.kPrimaryOrange,
        _ButtonVariant.secondary => Colors.transparent,
        _ButtonVariant.danger    => AppColors.kHealthRed,
        _ButtonVariant.ghost     => Colors.transparent,
      };

  Color get _fgColor => switch (widget._variant) {
        _ButtonVariant.primary   => Colors.white,
        _ButtonVariant.secondary => AppColors.kPrimaryOrange,
        _ButtonVariant.danger    => Colors.white,
        _ButtonVariant.ghost     => AppColors.kPrimaryOrange,
      };

  Border? get _border => switch (widget._variant) {
        _ButtonVariant.secondary =>
          const Border.fromBorderSide(
              BorderSide(color: AppColors.kPrimaryOrange, width: 1.5)),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isDisabled && !widget.isLoading) widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(16),
              border: _border,
              boxShadow: widget._variant == _ButtonVariant.primary && !isDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.kPrimaryOrange.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _fgColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: _fgColor, size: 18),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

enum _ButtonVariant { primary, secondary, danger, ghost }

// ─── AppIconButton ────────────────────────────────────────────────────────────

/// Tombol ikon bulat dengan tap feedback yang konsisten.
class AppIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.size = 44,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  AppColors.kPrimaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                    color: widget.iconColor ?? AppColors.kPrimaryOrange,
                    size: widget.size * 0.45),
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
