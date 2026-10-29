import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DonutSlice {
  const DonutSlice({required this.value, required this.color});

  final double value;
  final Color color;
}

/// Grafik donat animasi: irisan terbuka melingkar saat pertama tampil.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerTop,
    required this.centerBottom,
    this.size = 180,
    this.strokeWidth = 24,
  });

  final List<DonutSlice> slices;
  final String centerTop;
  final String centerBottom;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // Kunci berubah saat data berubah, sehingga animasi diputar ulang.
    final String signature =
        slices.map((DonutSlice s) => s.value.round()).join('-');

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(signature),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progress, Widget? child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter(
                  slices: slices,
                  progress: progress,
                  strokeWidth: strokeWidth,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(strokeWidth + 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerTop,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.slateDark,
                        ),
                      ),
                      Text(centerBottom, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.strokeWidth,
  });

  final List<DonutSlice> slices;
  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - strokeWidth) / 2,
    );

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    double total = 0;
    for (final DonutSlice s in slices) {
      total += s.value;
    }
    if (total <= 0) return;

    const double gap = 0.05;
    double start = -math.pi / 2;
    for (final DonutSlice slice in slices) {
      final double fraction = slice.value / total;
      final double fullSweep = fraction * math.pi * 2 * progress;
      final double sweep = slices.length > 1
          ? math.max(0.0, fullSweep - gap * progress)
          : fullSweep;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(rect, start + (gap * progress) / 2, sweep, false, paint);
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.slices != slices ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
