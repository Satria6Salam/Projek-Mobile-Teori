import 'package:flutter/material.dart';

/// Angka yang "berhitung" naik/turun menuju nilai baru dengan animasi halus.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, Widget? child) {
        return Text(formatter(animated), style: style, textAlign: textAlign);
      },
    );
  }
}
