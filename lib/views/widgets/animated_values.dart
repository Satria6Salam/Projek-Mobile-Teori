import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Warna bilah progres: hijau, lalu kuning mendekati batas, merah saat lewat.
Color progressColor(double ratio) {
  if (ratio >= 1) return AppColors.error;
  if (ratio >= 0.8) return AppColors.warning;
  return AppColors.emerald;
}

/// Angka rupiah yang naik dari nol ke nilainya, dan ikut naik saat nilai berubah.
class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double current, Widget? child) {
        return Text(AppFormatters.rupiah(current), style: style);
      },
    );
  }
}

/// Bilah progres yang bergerak dari kiri ke nilainya, dengan warna sesuai pemakaian.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({super.key, required this.ratio, this.height = 10});

  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: progressColor(ratio),
            backgroundColor: AppColors.border,
          ),
        );
      },
    );
  }
}
