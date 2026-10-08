import 'package:flutter/material.dart';

/// Section Soft brand colors — single source of truth.
///
/// Import this file wherever you need brand colors instead of
/// redefining them locally:
///
///   import 'app_colors.dart';
///
///   Container(color: AppColors.navy)
class AppColors {
  AppColors._(); // prevents instantiation

  // Core brand colors
  static const Color navy = Color(0xFF121F42);
  static const Color blue = Color(0xFF2F4FBF);
  static const Color teal = Color(0xFF2FA8C9);

  // Neutrals / surfaces
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7EAF1);

  // Text
  static const Color textPrimary = Color(0xFF121F42); // same as navy
  static const Color textMuted = Color(0xFF8A93A6);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF2FBF71);
  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [navy, blue],
  );
}
