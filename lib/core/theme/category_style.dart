import 'package:flutter/material.dart';

import '../constants/category_names.dart';
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

  static CategoryStyle _make(IconData icon, int rgb) {
    return CategoryStyle(
      icon: icon,
      color: Color(0xFF000000 | rgb),
      tint: Color(0x1F000000 | rgb),
    );
  }

  /// Gaya kustom dari pengguna (ikon dan warna), diisi dari tabel categories.
  static final Map<String, CategoryStyle> _custom = <String, CategoryStyle>{};

  /// Mendaftarkan ikon dan warna kustom untuk satu kategori (berdasarkan nama).
  static void registerCustom(
    String categoryName, {
    required IconData icon,
    required int colorRgb,
  }) {
    _custom[categoryName.trim()] = _make(icon, colorRgb);
  }

  /// Menghapus semua gaya kustom; dipanggil sebelum daftar kategori dimuat ulang.
  static void clearCustom() => _custom.clear();

  factory CategoryStyle.of(String categoryName) {
    final CategoryStyle? custom = _custom[categoryName.trim()];
    if (custom != null) return custom;
    switch (categoryName.trim()) {
      case CategoryNames.konsumsi:
        return _make(AppIcons.utensils, 0x10B981);
      case CategoryNames.bahanMakanan:
        return _make(AppIcons.shoppingBasket, 0x84CC16);
      case CategoryNames.transportasi:
        return _make(AppIcons.car, 0x3B82F6);
      case CategoryNames.kesehatan:
        return _make(AppIcons.heartPulse, 0xEC4899);
      case CategoryNames.perawatanDiri:
        return _make(AppIcons.sparkles, 0xA855F7);
      case CategoryNames.rumahTangga:
        return _make(AppIcons.bed, 0x14B8A6);
      case CategoryNames.pakaianAksesori:
        return _make(AppIcons.shirt, 0xD946EF);
      case CategoryNames.elektronik:
        return _make(AppIcons.cpu, 0x6366F1);
      case CategoryNames.pendidikan:
        return _make(AppIcons.graduationCap, 0x0EA5E9);
      case CategoryNames.hiburan:
        return _make(AppIcons.gamepad, 0x8B5CF6);
      case CategoryNames.tagihanUtilitas:
        return _make(AppIcons.zap, 0xEAB308);
      case CategoryNames.jasaLayanan:
        return _make(AppIcons.wrench, 0x06B6D4);
      case CategoryNames.donasiSosial:
        return _make(AppIcons.heartHandshake, 0xFB7185);
      case CategoryNames.belanja:
        return _make(AppIcons.shoppingBag, 0xF97316);
      default:
        return _make(AppIcons.tag, 0x64748B);
    }
  }
}
