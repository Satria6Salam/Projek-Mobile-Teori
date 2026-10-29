import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

/// Kartu kecil berisi satu angka penting (ikon, label, nilai, keterangan).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.footnote,
    this.color = AppColors.emeraldDark,
    this.tint = AppColors.emeraldTint,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final String? footnote;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: value),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(
              footnote ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}
