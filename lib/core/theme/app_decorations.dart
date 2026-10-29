import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Radius sudut dinamis sesuai panduan desain.
class AppRadius {
  AppRadius._();

  static const double cardLarge = 24; // kartu besar (dasbor utama)
  static const double card = 16; // kartu standar
  static const double control = 12; // input field & tombol aksi
}

/// Jarak antar komponen (ruang putih ekstra, minimal 16-24px).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Dekorasi siap pakai: kartu putih dengan bayangan lembut (soft depth).
class AppDecorations {
  AppDecorations._();

  /// Bayangan difusi: blur 12px, opacity 4%.
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static BoxDecoration card({double radius = AppRadius.card}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: softShadow,
    );
  }
}
