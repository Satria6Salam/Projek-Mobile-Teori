import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/category_style.dart';
import '../../data/models/category_model.dart';

/// Pemilih kategori berbentuk deretan pil yang dapat diketuk.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.errorText,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Pengeluaran',
          style: textTheme.labelLarge?.copyWith(color: AppColors.coolGray),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final CategoryModel category in categories)
              if (category.id != null)
                _CategoryChip(
                  category: category,
                  isSelected: category.id == selectedId,
                  onTap: () => onSelected(category.id ?? 0),
                ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText ?? '',
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CategoryStyle style = CategoryStyle.of(category.name);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.control),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? style.tint : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: isSelected ? style.color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              style.icon,
              size: 18,
              color: isSelected ? style.color : AppColors.coolGray,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        isSelected ? AppColors.slateDark : AppColors.coolGray,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
