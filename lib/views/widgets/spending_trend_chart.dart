import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/insight_service.dart';

/// Grafik batang pengeluaran harian; batang tumbuh dengan animasi dan dapat diketuk.
class SpendingTrendChart extends StatefulWidget {
  const SpendingTrendChart({super.key, required this.data, this.height = 130});

  final List<DailySpending> data;
  final double height;

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<DailySpending> data = widget.data;

    double maxValue = 0;
    for (final DailySpending d in data) {
      maxValue = math.max(maxValue, d.amount);
    }
    if (data.isEmpty || maxValue <= 0) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Belum ada pengeluaran pada bulan ini',
            style: textTheme.bodySmall,
          ),
        ),
      );
    }

    final int? selected = (_selected != null && _selected! < data.length)
        ? _selected
        : null;
    final String caption = selected == null
        ? 'Ketuk batang untuk melihat rincian harian'
        : 'Tgl ${data[selected].day}  •  ${AppFormatters.rupiah(data[selected].amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
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
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < data.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _selected = _selected == i ? null : i;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.2),
                      child: _Bar(
                        fraction: data[i].amount / maxValue,
                        hasValue: data[i].amount > 0,
                        isSelected: selected == i,
                        delay: i,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: textTheme.bodySmall),
            Text('${(data.length / 2).round()}', style: textTheme.bodySmall),
            Text('${data.length}', style: textTheme.bodySmall),
          ],
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
    required this.delay,
  });

  final double fraction;
  final bool hasValue;
  final bool isSelected;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.emeraldDark
        : (hasValue ? AppColors.emerald : AppColors.border);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: Duration(milliseconds: 500 + delay * 14),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}
