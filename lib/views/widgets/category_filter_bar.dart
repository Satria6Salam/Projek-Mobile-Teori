import 'package:flutter/material.dart';

import '../../core/constants/category_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/category_style.dart';
import '../../data/models/category_summary_model.dart';

/// Deretan chip filter kategori yang dapat digulir ke samping.
/// Dapat memilih beberapa kategori sekaligus; "Semua" menghapus pilihan.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onClear,
  });

  /// Kategori yang memiliki transaksi pada periode terpilih.
  final List<CategorySummaryModel> categories;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final List<CategorySummaryModel> sorted =
        List<CategorySummaryModel>.of(categories)
          ..sort(
            (CategorySummaryModel a, CategorySummaryModel b) =>
                CategoryNames.rank(a.categoryName)
                    .compareTo(CategoryNames.rank(b.categoryName)),
          );

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: sorted.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _FilterChip(
              label: 'Semua',
              icon: AppIcons.layoutDashboard,
              color: AppColors.emeraldDark,
              tint: AppColors.emeraldTint,
              selected: selectedIds.isEmpty,
              onTap: onClear,
            );
          }
          final CategorySummaryModel c = sorted[index - 1];
          final CategoryStyle style = CategoryStyle.of(c.categoryName);
          return _FilterChip(
            label: c.categoryName,
            count: c.transactionCount,
            icon: style.icon,
            color: style.color,
            tint: style.tint,
            selected: selectedIds.contains(c.categoryId),
            onTap: () => onToggle(c.categoryId),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? tint : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.coolGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: selected ? AppColors.slateDark : AppColors.coolGray,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.coolGray,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
