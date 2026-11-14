import 'package:flutter/material.dart';

import '../../data/models/category_model.dart';
import 'app_icons.dart';
import 'category_style.dart';

/// Pilihan ikon dan warna untuk kategori yang dapat diatur pengguna.
class CategoryPalette {
  CategoryPalette._();

  /// Kunci ikon (disimpan di database) -> ikon.
  static final Map<String, IconData> icons = <String, IconData>{
    'utensils': AppIcons.utensils,
    'basket': AppIcons.shoppingBasket,
    'car': AppIcons.car,
    'heart': AppIcons.heartPulse,
    'sparkles': AppIcons.sparkles,
    'bed': AppIcons.bed,
    'shirt': AppIcons.shirt,
    'cpu': AppIcons.cpu,
    'school': AppIcons.graduationCap,
    'gamepad': AppIcons.gamepad,
    'zap': AppIcons.zap,
    'wrench': AppIcons.wrench,
    'handshake': AppIcons.heartHandshake,
    'bag': AppIcons.shoppingBag,
    'tag': AppIcons.tag,
  };

  /// Warna RGB yang tersedia.
  static const List<int> colors = <int>[
    0x10B981,
    0x3B82F6,
    0xEF4444,
    0xF59E0B,
    0x8B5CF6,
    0xEC4899,
    0x14B8A6,
    0x64748B,
  ];

  static IconData iconFor(String? key) => icons[key] ?? AppIcons.tag;

  /// Mengisi ulang gaya kustom dari daftar kategori (dipanggil saat aplikasi
  /// dibuka dan setelah kategori diubah).
  static void applyTo(List<CategoryModel> categories) {
    CategoryStyle.clearCustom();
    for (final CategoryModel category in categories) {
      final int? color = category.colorValue;
      final String? key = category.iconKey;
      if (color == null && key == null) continue;
      CategoryStyle.registerCustom(
        category.name,
        icon: iconFor(key),
        colorRgb: color ?? 0x64748B,
      );
    }
  }
}
