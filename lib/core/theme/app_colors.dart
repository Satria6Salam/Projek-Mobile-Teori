import 'package:flutter/material.dart';

/// Palet warna SmartReceipt (Kepercayaan, Fokus, dan Kejelasan Finansial).
class AppColors {
  AppColors._();

  // Latar belakang & permukaan
  static const Color offWhite =
      Color(0xFFF4F7F5); // latar belakang utama (sedikit kehijauan)
  static const Color white = Color(0xFFFFFFFF); // permukaan kartu

  // Aksen utama: Hijau Zamrud (Emerald)
  // Aksen utama: Hijau Hutan (forest green), lebih tegas dan elegan.
  static const Color emerald = Color(0xFF16855A);
  static const Color emeraldDark = Color(0xFF0F6B47); // hover / pressed
  static const Color emeraldDeep = Color(0xFF0B5238); // teks pada lencana hijau
  static const Color forest = Color(0xFF083D2A); // kartu gelap
  static const Color emeraldLight = Color(0xFF34C38A); // sorotan grafik
  static const Color mint = Color(0xFFDDF3E8); // latar ikon lembut
  static const Color emeraldTint = Color(0x1A16855A); // hijau transparan 10%

  // Teks & tipografi
  static const Color slateDark = Color(0xFF0F172A); // judul utama
  static const Color coolGray =
      Color(0xFF64748B); // subjudul, label, teks pendukung

  // Warna semantik
  static const Color error = Color(0xFFEF4444);
  static const Color errorTint = Color(0x1AEF4444);

  // Peringatan ringan (misalnya: hasil AI perlu dicek)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningTint = Color(0x1FF59E0B);
  static const Color warningDeep = Color(0xFFB45309);

  // Garis tipis halus & bayangan
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x0A000000); // hitam opacity ~4%

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E9A68), emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradien kartu utama (saldo/pengeluaran) seperti kartu bank.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A8A5C), emeraldDeep, forest],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
