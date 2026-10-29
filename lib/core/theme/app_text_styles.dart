import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi: Plus Jakarta Sans (keterbacaan angka tinggi untuk aplikasi finansial).
class AppTextStyles {
  AppTextStyles._();

  static TextTheme buildTextTheme() {
    final TextTheme base = GoogleFonts.plusJakartaSansTextTheme();

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.slateDark,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.slateDark,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.slateDark,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.coolGray,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.slateDark,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.coolGray,
      ),
    );
  }

  /// Gaya khusus nominal uang: angka lebar sama (tabular) agar rapi sejajar.
  static TextStyle amount({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.slateDark,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Gaya teks pada lencana (misal: lencana kategori / confidence AI).
  static TextStyle badge({Color color = AppColors.emeraldDeep}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
