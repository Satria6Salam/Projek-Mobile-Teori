import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_summary_model.dart';
import 'category_badge.dart';

/// Rekap singkat beberapa kategori teratas (untuk halaman Beranda).
class CategoryMiniList extends StatelessWidget {
  const CategoryMiniList({
    super.key,
    required this.summaries,
    required this.percentageOf,
    this.limit = 4,
    this.onSelect,
  });

  final List<CategorySummaryModel> summaries;
  final double Function(CategorySummaryModel summary) percentageOf;
  final int limit;
  final ValueChanged<CategorySummaryModel>? onSelect;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<CategorySummaryModel> top = summaries.take(limit).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        children: [
          for (int i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.control),
              onTap: onSelect == null ? null : () => onSelect?.call(top[i]),
              child: Column(
                children: [
                  Row(
                    children: [
                      CategoryIconBox(
                          categoryName: top[i].categoryName, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          top[i].categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        AppFormatters.rupiah(top[i].totalAmount),
                        style: AppTextStyles.amount(size: 14),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          AppFormatters.percent(percentageOf(top[i])),
                          textAlign: TextAlign.right,
                          style: textTheme.labelMedium?.copyWith(
                            color: CategoryStyle.of(top[i].categoryName).color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: percentageOf(top[i]).clamp(0.0, 1.0).toDouble(),
                    ),
                    duration: Duration(milliseconds: 650 + i * 120),
                    curve: Curves.easeOutCubic,
                    builder:
                        (BuildContext context, double value, Widget? child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CategoryStyle.of(top[i].categoryName).color,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
