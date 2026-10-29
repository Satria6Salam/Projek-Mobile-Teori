import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Satu batang pada grafik tren.
class TrendBar {
  const TrendBar({
    required this.label,
    required this.caption,
    required this.amount,
    this.isHighlighted = false,
  });

  /// Label singkat di bawah batang (mis. "J" atau "2024").
  final String label;

  /// Keterangan lengkap saat batang dipilih (mis. "Maret 2026").
  final String caption;
  final double amount;

  /// True untuk periode yang sedang dilihat pada Dasbor.
  final bool isHighlighted;
}

/// Grafik batang tren dengan label. Ketuk batang untuk melihat nilainya, lalu
/// tombol "Lihat" untuk membuka periode tersebut pada Dasbor.
class BarTrendChart extends StatefulWidget {
  const BarTrendChart({
    super.key,
    required this.bars,
    required this.onOpen,
    this.height = 150,
  });

  final List<TrendBar> bars;
  final ValueChanged<int> onOpen;
  final double height;

  @override
  State<BarTrendChart> createState() => _BarTrendChartState();
}

class _BarTrendChartState extends State<BarTrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<TrendBar> bars = widget.bars;

    double maxValue = 0;
    for (final TrendBar b in bars) {
      maxValue = math.max(maxValue, b.amount);
    }
    if (bars.isEmpty || maxValue <= 0) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('Belum ada data untuk ditampilkan', style: textTheme.bodySmall),
        ),
      );
    }

    final int? selected =
        (_selected != null && _selected! < bars.length) ? _selected : null;
    final String caption = selected == null
        ? 'Ketuk batang untuk melihat nilainya'
        : '${bars[selected].caption}  •  ${AppFormatters.rupiah(bars[selected].amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  caption,
                  key: ValueKey<String>(caption),
                  style: textTheme.labelLarge?.copyWith(
                    color: selected == null
                        ? AppColors.coolGray
                        : AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
            if (selected != null)
              TextButton(
                onPressed: () => widget.onOpen(selected),
                child: const Text('Lihat'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < bars.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _selected = _selected == i ? null : i;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Expanded(
                            child: _Bar(
                              fraction: bars[i].amount / maxValue,
                              hasValue: bars[i].amount > 0,
                              isSelected: selected == i,
                              isHighlighted: bars[i].isHighlighted,
                              delay: i,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bars[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: textTheme.labelMedium?.copyWith(
                              color: bars[i].isHighlighted
                                  ? AppColors.emeraldDeep
                                  : AppColors.coolGray,
                              fontWeight: bars[i].isHighlighted
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.hasValue,
    required this.isSelected,
    required this.isHighlighted,
    required this.delay,
  });

  final double fraction;
  final bool hasValue;
  final bool isSelected;
  final bool isHighlighted;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.emeraldDark
        : (isHighlighted
            ? AppColors.emerald
            : (hasValue ? const Color(0xFF6EE7B7) : AppColors.border));

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: Duration(milliseconds: 550 + delay * 40),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        final double factor = math.min(1.0, math.max(value, 0.03));
        return Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(heightFactor: factor, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }
}
