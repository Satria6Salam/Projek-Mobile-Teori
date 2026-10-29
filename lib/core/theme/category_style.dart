import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Ikon dan warna khas tiap kategori pengeluaran.
class CategoryStyle {
  const CategoryStyle({
    required this.icon,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final Color color;

  /// Warna latar lembut (opacity ~12%) untuk kotak ikon dan lencana.
  final Color tint;

  factory CategoryStyle.of(String categoryName) {
    switch (categoryName.trim().toLowerCase()) {
      case 'konsumsi':
        return CategoryStyle(
          icon: AppIcons.utensils,
          color: const Color(0xFF10B981),
          tint: const Color(0x1F10B981),
        );
      case 'transportasi':
        return CategoryStyle(
          icon: AppIcons.car,
          color: const Color(0xFF3B82F6),
          tint: const Color(0x1F3B82F6),
        );
      case 'kesehatan':
        return CategoryStyle(
          icon: AppIcons.heartPulse,
          color: const Color(0xFFEC4899),
          tint: const Color(0x1FEC4899),
        );
      case 'belanja':
        return CategoryStyle(
          icon: AppIcons.shoppingBag,
          color: const Color(0xFFF59E0B),
          tint: const Color(0x1FF59E0B),
        );
      case 'elektronik':
        return CategoryStyle(
          icon: AppIcons.cpu,
          color: const Color(0xFF6366F1),
          tint: const Color(0x1F6366F1),
        );
      default:
        return CategoryStyle(
          icon: AppIcons.tag,
          color: const Color(0xFF64748B),
          tint: const Color(0x1F64748B),
        );
    }
  }
}
