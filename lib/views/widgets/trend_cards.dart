import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/dashboard_period.dart';
import '../../core/utils/formatters.dart';
import '../../services/insight_service.dart';
import 'bar_trend_chart.dart';
import 'insight_card.dart';

/// Kartu tren bulanan: total pengeluaran tiap bulan pada satu tahun.
class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({
    super.key,
    required this.trends,
    required this.period,
    required this.onOpenMonth,
  });

  final TrendAnalytics trends;
  final DashboardPeriod period;

  /// Dipanggil dengan nomor bulan (1 - 12) yang ingin dibuka.
  final ValueChanged<int> onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int year = trends.year;
    final List<Insight> insights = trends.insights
        .where((Insight i) => i.topic == InsightTopic.monthlyTrend)
        .toList();
    final int? peak = trends.peakMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.card(radius: AppRadius.cardLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tren Bulanan $year', style: textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('Total pengeluaran per bulan', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              BarTrendChart(
                bars: [
                  for (int m = 1; m <= 12; m++)
                    TrendBar(
                      label: AppFormatters.monthInitial(m),
                      caption: '${AppFormatters.monthName(m)} $year',
                      amount: m <= trends.monthlyTotals.length
                          ? trends.monthlyTotals[m - 1]
                          : 0,
                      isHighlighted: period.mode == PeriodMode.month &&
                          period.anchor.year == year &&
                          period.anchor.month == m,
                    ),
                ],
                onOpen: (int index) => onOpenMonth(index + 1),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Rata-rata per bulan',
                      value: AppFormatters.rupiah(trends.monthlyAverage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Bulan tertinggi',
                      value: peak == null
                          ? '-'
                          : AppFormatters.monthName(peak),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final Insight insight in insights) ...[
          const SizedBox(height: 12),
          InsightCard(insight: insight),
        ],
      ],
    );
  }
}

/// Kartu tren tahunan: total pengeluaran tiap tahun yang memiliki data.
class YearlyTrendCard extends StatelessWidget {
  const YearlyTrendCard({
    super.key,
    required this.trends,
    required this.period,
    required this.onOpenYear,
  });

  final TrendAnalytics trends;
  final DashboardPeriod period;
  final ValueChanged<int> onOpenYear;

  static const int _maxYears = 8;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<YearlyPoint> all = trends.yearlyTotals;
    final List<YearlyPoint> points =
        all.length > _maxYears ? all.sublist(all.length - _maxYears) : all;
    final List<Insight> insights = trends.insights
        .where((Insight i) => i.topic == InsightTopic.yearlyTrend)
        .toList();

    double selectedYearTotal = 0;
    for (final YearlyPoint p in all) {
      if (p.year == period.anchor.year) selectedYearTotal = p.amount;
    }
    final double? yoy = trends.yearOverYearPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.card(radius: AppRadius.cardLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tren Tahunan', style: textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('Total pengeluaran per tahun', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              BarTrendChart(
                bars: [
                  for (final YearlyPoint p in points)
                    TrendBar(
                      label: '${p.year}',
                      caption: 'Tahun ${p.year}',
                      amount: p.amount,
                      isHighlighted: p.year == period.anchor.year,
                    ),
                ],
                onOpen: (int index) => onOpenYear(points[index].year),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Total ${period.anchor.year}',
                      value: AppFormatters.rupiah(selectedYearTotal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Dibanding tahun lalu',
                      value: yoy == null
                          ? '-'
                          : '${yoy >= 0 ? '+' : '-'}${yoy.abs().round()}%',
                      valueColor: yoy == null
                          ? AppColors.slateDark
                          : (yoy >= 0 ? AppColors.warningDeep : AppColors.emeraldDeep),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final Insight insight in insights) ...[
          const SizedBox(height: 12),
          InsightCard(insight: insight),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.slateDark,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.amount(size: 15, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
