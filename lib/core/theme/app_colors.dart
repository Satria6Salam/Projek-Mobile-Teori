import 'package:flutter/material.dart';

/// Palet warna SmartReceipt (Kepercayaan, Fokus, dan Kejelasan Finansial).
class AppColors {
  AppColors._();

  // Latar belakang & permukaan
  static const Color offWhite = Color(0xFFF8FAFC); // latar belakang utama
  static const Color white = Color(0xFFFFFFFF); // permukaan kartu

  // Aksen utama: Hijau Zamrud (Emerald)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669); // hover / pressed
  static const Color emeraldDeep = Color(0xFF047857); // teks pada lencana hijau
  static const Color emeraldTint = Color(0x1A10B981); // hijau transparan 10%

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
    colors: [emerald, emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
