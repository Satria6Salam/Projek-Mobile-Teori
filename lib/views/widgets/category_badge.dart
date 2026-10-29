import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/category_style.dart';

/// Kotak ikon berwarna sesuai kategori.
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({super.key, required this.categoryName, this.size = 44});

  final String categoryName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final CategoryStyle style = CategoryStyle.of(categoryName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(style.icon, size: size * 0.5, color: style.color),
    );
  }
}

/// Lencana kategori berbentuk pil (ikon + nama).
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final CategoryStyle style = CategoryStyle.of(categoryName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.color),
          const SizedBox(width: 6),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.slateDark,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}
