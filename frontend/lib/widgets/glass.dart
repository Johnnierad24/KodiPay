import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Shared frosted-glass design primitives used across the onboarding, auth, and
/// forgot-password screens so the branded experience stays uniform.

const String kAuthBackgroundAsset = 'assets/images/welcome_bg.jpg';

/// Full-screen, slightly-blurred branded background (the welcome photo) with a
/// dark scrim so the foreground glass and white text stay legible.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid base so blurred edges never reveal transparency.
        const ColoredBox(color: AppColors.kodiNavy),
        // The photo, gently blurred ("a little blurry, not so blurry").
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Image.asset(
            kAuthBackgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.kodiBlue, AppColors.kodiNavy],
                ),
              ),
            ),
          ),
        ),
        // Dark scrim for contrast.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80001220), Color(0xBF001220)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A frosted-glass container: blurs whatever sits behind it and tints it with a
/// translucent white wash and a subtle light border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double opacity;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 18,
    this.opacity = 0.14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: AppColors.white.withValues(alpha: 0.28)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A text field styled for placement on top of glass / dark imagery: white text,
/// translucent fill, and light borders.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.hintText,
  });

  OutlineInputBorder _border(double alpha, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: AppColors.white.withValues(alpha: alpha), width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppColors.white),
      cursorColor: AppColors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.8)),
        floatingLabelStyle: const TextStyle(color: AppColors.white),
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.45)),
        prefixIcon:
            Icon(icon, color: AppColors.white.withValues(alpha: 0.8)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.10),
        enabledBorder: _border(0.25),
        focusedBorder: _border(0.7, 1.4),
        border: _border(0.25),
      ),
    );
  }
}
