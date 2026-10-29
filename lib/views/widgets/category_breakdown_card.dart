import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_summary_model.dart';
import 'category_badge.dart';
import 'donut_chart.dart';

/// Rekap pengeluaran per kategori: grafik donat + rincian dengan bilah persentase.
/// Dihitung dari rincian barang, sehingga satu struk bisa masuk ke banyak kategori.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.summaries,
    required this.percentageOf,
    required this.total,
  });

  final List<CategorySummaryModel> summaries;
  final double Function(CategorySummaryModel summary) percentageOf;
  final double total;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekap per Kategori', style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            'Dihitung dari barang di setiap struk',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: DonutChart(
              slices: [
                for (final CategorySummaryModel s in summaries)
                  DonutSlice(
                    value: s.totalAmount,
                    color: CategoryStyle.of(s.categoryName).color,
                  ),
              ],
              centerTop: '${summaries.length} kategori',
              centerBottom: AppFormatters.rupiah(total),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < summaries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _CategoryRow(
              summary: summaries[i],
              fraction: percentageOf(summaries[i]),
              index: i,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.summary,
    required this.fraction,
    required this.index,
  });

  final CategorySummaryModel summary;
  final double fraction;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CategoryStyle style = CategoryStyle.of(summary.categoryName);

    return Column(
      children: [
        Row(
          children: [
            CategoryIconBox(categoryName: summary.categoryName, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.categoryName, style: textTheme.titleMedium),
                  Text(
                    '${summary.transactionCount} transaksi',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.rupiah(summary.totalAmount),
                  style: AppTextStyles.amount(size: 14),
                ),
                Text(
                  AppFormatters.percent(fraction),
                  style: textTheme.labelMedium?.copyWith(color: style.color),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: fraction.clamp(0.0, 1.0).toDouble(),
          ),
          duration: Duration(milliseconds: 700 + index * 120),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(style.color),
              ),
            );
          },
        ),
      ],
    );
  }
}
